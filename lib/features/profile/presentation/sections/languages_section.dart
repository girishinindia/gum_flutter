// Languages section.
//
// Mirrors Skills: chip list of user-language rows backed by master
// languages from /languages. Each entry carries a proficiency band
// plus can_read / can_write / can_speak toggles + is_primary +
// is_native. The chip shows iso_code if available, full name in
// the edit dialog.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../data/masters_api.dart';
import '../../domain/master_models.dart';
import '../../domain/user_sub_resources.dart';
import '../widgets/searchable_chip_picker.dart';

class LanguagesSection extends StatefulWidget {
  const LanguagesSection({super.key});

  @override
  State<LanguagesSection> createState() => _LanguagesSectionState();
}

class _LanguagesSectionState extends State<LanguagesSection> {
  final _masters = MastersApi();
  bool _busy = false;
  String? _formError;

  static const _proficiencies = ['basic', 'conversational', 'professional', 'fluent', 'native'];

  Future<void> _openAddPicker(List<UserLanguage> existing) async {
    final excludeIds = existing.map((u) => u.languageId).toSet();
    final picked = await showChipPicker<MasterLanguage>(
      context: context,
      title:   'Add language',
      placeholder: 'Search languages…',
      search:  (q) => _masters.searchLanguages(q, limit: 30),
      labelOf: (l) => l.name,
      idOf:    (l) => l.id,
      subtitleOf: (l) => l.nativeName,
      excludeIds: excludeIds,
    );
    if (!mounted || picked == null) return;
    final entry = await _showLanguageDialog(name: picked.name);
    if (entry == null || !mounted) return;
    await _persistAdd(picked, entry);
  }

  Future<void> _openEdit(UserLanguage row) async {
    final name = row.language?.name ?? '#${row.languageId}';
    final entry = await _showLanguageDialog(
      name: name,
      initialProficiency: row.proficiencyLevel ?? 'conversational',
      initialRead:        row.canRead ?? false,
      initialWrite:       row.canWrite ?? false,
      initialSpeak:       row.canSpeak ?? false,
      initialNative:      row.isNative ?? false,
      initialPrimary:     row.isPrimary ?? false,
      isEdit: true,
    );
    if (entry == null || !mounted) return;
    if (entry.delete) {
      await _persistDelete(row);
    } else {
      await _persistUpdate(row, entry);
    }
  }

  Future<_LangResult?> _showLanguageDialog({
    required String name,
    String  initialProficiency = 'conversational',
    bool    initialRead   = false,
    bool    initialWrite  = false,
    bool    initialSpeak  = true,
    bool    initialNative = false,
    bool    initialPrimary = false,
    bool    isEdit = false,
  }) {
    return showDialog<_LangResult>(
      context: context,
      builder: (ctx) {
        String prof    = initialProficiency;
        bool canRead   = initialRead;
        bool canWrite  = initialWrite;
        bool canSpeak  = initialSpeak;
        bool isNative  = initialNative;
        bool isPrimary = initialPrimary;
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            title: Text(isEdit ? name : 'Add $name'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: prof,
                    decoration: const InputDecoration(labelText: 'Proficiency'),
                    items: _proficiencies.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(_titleCase(p)),
                        )).toList(),
                    onChanged: (v) => setLocal(() => prof = v ?? prof),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I can read'),
                    value: canRead,
                    onChanged: (v) => setLocal(() => canRead = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I can write'),
                    value: canWrite,
                    onChanged: (v) => setLocal(() => canWrite = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('I can speak'),
                    value: canSpeak,
                    onChanged: (v) => setLocal(() => canSpeak = v ?? false),
                  ),
                  const Divider(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Native speaker'),
                    value: isNative,
                    onChanged: (v) => setLocal(() => isNative = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary language'),
                    value: isPrimary,
                    onChanged: (v) => setLocal(() => isPrimary = v ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              if (isEdit)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                  onPressed: () => Navigator.of(ctx).pop(_LangResult.delete()),
                  child: const Text('Delete'),
                ),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(_LangResult.save(
                  proficiency: prof,
                  canRead: canRead, canWrite: canWrite, canSpeak: canSpeak,
                  isNative: isNative, isPrimary: isPrimary,
                )),
                child: Text(isEdit ? 'Save' : 'Add'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _persistAdd(MasterLanguage master, _LangResult res) async {
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await bloc.repository.languagesApi.add({
        'language_id':       master.id,
        'proficiency_level': res.proficiency,
        'can_read':          res.canRead,
        'can_write':         res.canWrite,
        'can_speak':         res.canSpeak,
        'is_primary':        res.isPrimary,
        'is_native':         res.isNative,
      });
      final fresh = await bloc.repository.languagesApi.list();
      if (!mounted) return;
      bloc.add(ProfileLanguagesReplaced(fresh));
      messenger.showSnackBar(SnackBar(content: Text('Added "${master.name}".')));
    } on ApiError catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistUpdate(UserLanguage row, _LangResult res) async {
    if (row.id == null) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _formError = null;
    });
    try {
      await bloc.repository.languagesApi.update(row.id!, {
        'proficiency_level': res.proficiency,
        'can_read':          res.canRead,
        'can_write':         res.canWrite,
        'can_speak':         res.canSpeak,
        'is_primary':        res.isPrimary,
        'is_native':         res.isNative,
      });
      final fresh = await bloc.repository.languagesApi.list();
      if (!mounted) return;
      bloc.add(ProfileLanguagesReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
    } on ApiError catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistDelete(UserLanguage row) async {
    if (row.id == null) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await bloc.repository.languagesApi.delete(row.id!);
      final fresh = await bloc.repository.languagesApi.list();
      if (!mounted) return;
      bloc.add(ProfileLanguagesReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Removed.')));
    } on ApiError catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Languages')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = state.bundle!.languages;
          return SafeArea(
            child: list.isEmpty
                ? _empty(context)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _LanguageRow(
                      entry: list[i],
                      onTap: _busy ? null : () => _openEdit(list[i]),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (_, state) {
          if (!state.isLoaded || state.bundle == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Add language'),
            onPressed: _busy ? null : () => _openAddPicker(state.bundle!.languages),
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
            Icon(Icons.translate_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No languages added',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "Add languages you speak, read, or write.",
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

class _LangResult {
  _LangResult.save({
    required this.proficiency,
    required this.canRead,
    required this.canWrite,
    required this.canSpeak,
    required this.isNative,
    required this.isPrimary,
  }) : delete = false;
  _LangResult.delete()
      : proficiency = 'conversational',
        canRead = false, canWrite = false, canSpeak = false,
        isNative = false, isPrimary = false,
        delete = true;

  final String proficiency;
  final bool   canRead;
  final bool   canWrite;
  final bool   canSpeak;
  final bool   isNative;
  final bool   isPrimary;
  final bool   delete;
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.entry, required this.onTap});

  final UserLanguage entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = entry.language?.name ?? '#${entry.languageId}';
    final iso  = entry.language?.isoCode ?? '';
    final prof = entry.proficiencyLevel ?? 'conversational';
    final caps = <String>[
      if (entry.canRead  == true) 'R',
      if (entry.canWrite == true) 'W',
      if (entry.canSpeak == true) 'S',
    ].join(' · ');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            iso.isNotEmpty ? iso.toUpperCase() : name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
            if (entry.isPrimary == true)
              Icon(Icons.star, size: 16, color: theme.colorScheme.tertiary),
            if (entry.isNative == true) ...[
              const SizedBox(width: 4),
              Icon(Icons.public, size: 16, color: theme.colorScheme.secondary),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [prof.replaceAll('_', ' '), if (caps.isNotEmpty) caps].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
