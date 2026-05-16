// Skills section.
//
// Each user-skill is a chip with proficiency band. Add via the
// SearchableChipPicker (debounced server search against /skills).
// On pick → open a small proficiency dialog → POST /user-skills/me.
// Tap an existing chip → edit (proficiency, years, is_primary).
//
// The "no chip without master row" invariant is enforced by the
// picker (you can't free-text a skill that's not in `/skills`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../data/masters_api.dart';
import '../../domain/master_models.dart';
import '../../domain/user_sub_resources.dart';
import '../widgets/searchable_chip_picker.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  final _masters = MastersApi();
  bool _busy = false;
  String? _formError;

  static const _proficiencies = ['beginner', 'elementary', 'intermediate', 'advanced', 'expert'];

  Future<void> _openAddPicker(List<UserSkill> existing) async {
    final excludeIds = existing.map((u) => u.skillId).toSet();
    final picked = await showChipPicker<MasterSkill>(
      context: context,
      title:   'Add skill',
      placeholder: 'Search skills…',
      search:  (q) => _masters.searchSkills(q, limit: 30),
      labelOf: (s) => s.name,
      idOf:    (s) => s.id,
      subtitleOf: (s) => s.category,
      excludeIds: excludeIds,
    );
    if (!mounted || picked == null) return;
    final entry = await _showSkillDialog(initialProficiency: 'beginner');
    if (entry == null || !mounted) return;
    await _persistAdd(picked, entry);
  }

  Future<void> _openEdit(UserSkill row) async {
    final entry = await _showSkillDialog(
      initialProficiency:    row.proficiencyLevel ?? 'beginner',
      initialYears:          row.yearsOfExperience?.toString(),
      initialIsPrimary:      row.isPrimary ?? false,
      isEdit: true,
    );
    if (entry == null || !mounted) return;
    if (entry.delete) {
      await _persistDelete(row);
    } else {
      await _persistUpdate(row, entry);
    }
  }

  /// Show the add/edit dialog. The dialog body lives in a dedicated
  /// StatefulWidget (`_SkillDialogBody`) so the years-of-experience
  /// `TextEditingController` is properly disposed when the dialog
  /// closes — wrapping the body in a `StatefulBuilder` would leak it.
  /// Delete is handled inside the dialog itself (returns `delete()`)
  /// so the route popped is the dialog's, not the outer screen's.
  Future<_SkillFormResult?> _showSkillDialog({
    required String initialProficiency,
    String? initialYears,
    bool    initialIsPrimary = false,
    bool    isEdit = false,
  }) {
    return showDialog<_SkillFormResult>(
      context: context,
      builder: (ctx) => _SkillDialogBody(
        initialProficiency: initialProficiency,
        initialYears:       initialYears,
        initialIsPrimary:   initialIsPrimary,
        isEdit:             isEdit,
        proficiencies:      _proficiencies,
        titleCase:          _titleCase,
      ),
    );
  }

  Future<void> _persistAdd(MasterSkill master, _SkillFormResult res) async {
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await bloc.repository.skillsApi.add({
        'skill_id':            master.id,
        'proficiency_level':   res.proficiency,
        'years_of_experience': res.yearsOfExperience,
        'is_primary':          res.isPrimary,
      });
      final fresh = await bloc.repository.skillsApi.list();
      if (!mounted) return;
      bloc.add(ProfileSkillsReplaced(fresh));
      messenger.showSnackBar(SnackBar(content: Text('Added "${master.name}".')));
    } on ApiError catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistUpdate(UserSkill row, _SkillFormResult res) async {
    if (row.id == null) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await bloc.repository.skillsApi.update(row.id!, {
        'proficiency_level':   res.proficiency,
        'years_of_experience': res.yearsOfExperience,
        'is_primary':          res.isPrimary,
      });
      final fresh = await bloc.repository.skillsApi.list();
      if (!mounted) return;
      bloc.add(ProfileSkillsReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
    } on ApiError catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistDelete(UserSkill row) async {
    if (row.id == null) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await bloc.repository.skillsApi.delete(row.id!);
      final fresh = await bloc.repository.skillsApi.list();
      if (!mounted) return;
      bloc.add(ProfileSkillsReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Removed.')));
    } on ApiError catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Skills')),
      floatingActionButton: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (_, state) {
          if (!state.isLoaded || state.bundle == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Add skill'),
            onPressed: _busy ? null : () => _openAddPicker(state.bundle!.skills),
          );
        },
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final skills = state.bundle!.skills;
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: skills.isEmpty
                      ? _empty(context)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map((s) => _SkillChip(
                                  entry: s,
                                  onTap: _busy ? null : () => _openEdit(s),
                                )).toList(),
                          ),
                        ),
                ),
                if (_formError != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 18,
                            color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_formError!,
                            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No skills added',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "Pick from the catalogue and set your proficiency.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String s) =>
      s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _SkillFormResult {
  _SkillFormResult.save({
    required this.proficiency,
    required this.yearsOfExperience,
    required this.isPrimary,
  }) : delete = false;
  _SkillFormResult.delete()
      : proficiency       = 'beginner',
        yearsOfExperience = null,
        isPrimary         = false,
        delete            = true;

  final String   proficiency;
  final num?     yearsOfExperience;
  final bool     isPrimary;
  final bool     delete;
}

class _SkillDialogBody extends StatefulWidget {
  const _SkillDialogBody({
    required this.initialProficiency,
    required this.initialYears,
    required this.initialIsPrimary,
    required this.isEdit,
    required this.proficiencies,
    required this.titleCase,
  });

  final String  initialProficiency;
  final String? initialYears;
  final bool    initialIsPrimary;
  final bool    isEdit;
  final List<String> proficiencies;
  final String Function(String) titleCase;

  @override
  State<_SkillDialogBody> createState() => _SkillDialogBodyState();
}

class _SkillDialogBodyState extends State<_SkillDialogBody> {
  late final TextEditingController _yearsCtl;
  late String _prof;
  late bool   _isPrimary;

  @override
  void initState() {
    super.initState();
    _yearsCtl  = TextEditingController(text: widget.initialYears ?? '');
    _prof      = widget.initialProficiency;
    _isPrimary = widget.initialIsPrimary;
  }

  @override
  void dispose() {
    _yearsCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Edit skill' : 'Add skill'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              initialValue: _prof,
              decoration: const InputDecoration(labelText: 'Proficiency'),
              items: widget.proficiencies.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(widget.titleCase(p)),
                  )).toList(),
              onChanged: (v) => setState(() => _prof = v ?? _prof),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _yearsCtl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: const InputDecoration(
                labelText: 'Years of experience',
                hintText: 'e.g. 3',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Primary skill'),
              value: _isPrimary,
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isEdit)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(_SkillFormResult.delete()),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final years = num.tryParse(_yearsCtl.text.trim());
            Navigator.of(context).pop(_SkillFormResult.save(
              proficiency: _prof,
              yearsOfExperience: years,
              isPrimary: _isPrimary,
            ));
          },
          child: Text(widget.isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.entry, required this.onTap});

  final UserSkill   entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = entry.skill?.name ?? '#${entry.skillId}';
    final prof = entry.proficiencyLevel ?? 'beginner';
    final isPrimary = entry.isPrimary ?? false;
    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary) ...[
            Icon(Icons.star, size: 14, color: theme.colorScheme.tertiary),
            const SizedBox(width: 4),
          ],
          Text(name),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _abbr(prof),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      onPressed: onTap,
    );
  }

  String _abbr(String prof) {
    switch (prof) {
      case 'expert':       return 'EXP';
      case 'advanced':     return 'ADV';
      case 'intermediate': return 'INT';
      case 'elementary':   return 'ELEM';
      default:             return 'BEG';
    }
  }
}
