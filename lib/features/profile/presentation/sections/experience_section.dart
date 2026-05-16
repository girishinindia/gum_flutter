// Experience section.
//
// List of UserExperience rows + add/edit form. JSON-only — no
// multipart. Designation FK dropdown driven by /designations.
// "Currently working" toggle gates the end-date field.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../data/masters_api.dart';
import '../../domain/master_models.dart';
import '../../domain/user_sub_resources.dart';
import '../widgets/searchable_select.dart';

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Experience')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        onPressed: () => _openForm(context, null),
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = state.bundle!.experience;
          if (list.isEmpty) return _empty(context);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ExperienceCard(
              entry: list[i],
              onTap: () => _openForm(context, list[i]),
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
            Icon(Icons.work_outline, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No experience added',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "Add your jobs, internships, and freelance roles.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add role'),
              onPressed: () => _openForm(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, UserExperience? existing) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: _ExperienceFormScreen(existing: existing),
      ),
    ));
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.entry, required this.onTap});
  final UserExperience entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateRange = _formatRange(entry.startDate, entry.endDate, entry.isCurrentJob ?? false);
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
          child: const Icon(Icons.work_outline),
        ),
        title: Text(entry.jobTitle, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(entry.companyName, style: theme.textTheme.bodyMedium),
            if (dateRange.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(dateRange, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  static String _formatRange(String? start, String? end, bool ongoing) {
    String fmt(String? d) {
      if (d == null || d.isEmpty) return '';
      final dt = DateTime.tryParse(d);
      if (dt == null) return d;
      return DateFormat('MMM yyyy').format(dt);
    }
    final s = fmt(start);
    final e = ongoing ? 'Present' : fmt(end);
    if (s.isEmpty && e.isEmpty) return '';
    if (s.isEmpty) return e;
    if (e.isEmpty) return s;
    return '$s — $e';
  }
}

// ════════════════════════════════════════════════════════════════════
// Add / edit form
// ════════════════════════════════════════════════════════════════════

class _ExperienceFormScreen extends StatefulWidget {
  const _ExperienceFormScreen({this.existing});
  final UserExperience? existing;

  @override
  State<_ExperienceFormScreen> createState() => _ExperienceFormScreenState();
}

class _ExperienceFormScreenState extends State<_ExperienceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masters = MastersApi();

  final _companyCtl  = TextEditingController();
  final _titleCtl    = TextEditingController();
  final _deptCtl     = TextEditingController();
  final _locCtl      = TextEditingController();
  final _descCtl     = TextEditingController();
  final _achieveCtl  = TextEditingController();
  final _skillsCtl   = TextEditingController();
  final _salaryCtl   = TextEditingController();
  final _refNameCtl  = TextEditingController();
  final _refPhoneCtl = TextEditingController();
  final _refEmailCtl = TextEditingController();
  final _startCtl    = TextEditingController();
  final _endCtl      = TextEditingController();

  Designation? _designation;
  String?      _employmentType;
  String?      _workMode;
  bool         _isCurrentJob = false;

  List<Designation> _designations = const [];
  bool _designationsLoading = false;
  bool _submitting           = false;
  String? _formError;

  static const _employmentTypes = ['full_time', 'part_time', 'contract', 'internship',
      'freelance', 'self_employed', 'volunteer', 'apprenticeship', 'other'];
  static const _workModes = ['on_site', 'remote', 'hybrid'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _companyCtl.text  = e.companyName;
      _titleCtl.text    = e.jobTitle;
      _deptCtl.text     = e.department ?? '';
      _locCtl.text      = e.location ?? '';
      _descCtl.text     = e.description ?? '';
      _achieveCtl.text  = e.keyAchievements ?? '';
      _skillsCtl.text   = e.skillsUsed ?? '';
      _salaryCtl.text   = e.salaryRange ?? '';
      _refNameCtl.text  = e.referenceName ?? '';
      _refPhoneCtl.text = e.referencePhone ?? '';
      _refEmailCtl.text = e.referenceEmail ?? '';
      _startCtl.text    = e.startDate;
      _endCtl.text      = e.endDate ?? '';
      _employmentType   = e.employmentType;
      _workMode         = e.workMode;
      _isCurrentJob     = e.isCurrentJob ?? false;
      _designation      = e.designation != null
          ? Designation(id: e.designation!.id, name: e.designation!.name)
          : (e.designationId != null
              ? Designation(id: e.designationId!, name: '#${e.designationId}')
              : null);
    }
    _loadDesignations();
  }

  Future<void> _loadDesignations() async {
    setState(() => _designationsLoading = true);
    try {
      final rows = await _masters.listDesignations();
      if (!mounted) return;
      setState(() {
        _designations = rows;
        if (_designation != null) {
          final real = rows.where((d) => d.id == _designation!.id).cast<Designation?>().firstWhere(
            (d) => d != null, orElse: () => null);
          if (real != null) _designation = real;
        }
      });
    } catch (_) {/* leave empty */} finally {
      if (mounted) setState(() => _designationsLoading = false);
    }
  }

  @override
  void dispose() {
    _companyCtl.dispose();
    _titleCtl.dispose();
    _deptCtl.dispose();
    _locCtl.dispose();
    _descCtl.dispose();
    _achieveCtl.dispose();
    _skillsCtl.dispose();
    _salaryCtl.dispose();
    _refNameCtl.dispose();
    _refPhoneCtl.dispose();
    _refEmailCtl.dispose();
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctl) async {
    final firstDate = DateTime(1950);
    final lastDate  = DateTime.now();
    var initial = DateTime.tryParse(ctl.text) ?? DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate))   initial = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate:  lastDate,
    );
    if (picked != null) {
      setState(() => ctl.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final payload = <String, dynamic>{
      'company_name':       _companyCtl.text.trim(),
      'job_title':          _titleCtl.text.trim(),
      'designation_id':     _designation?.id,
      'employment_type':    _employmentType,
      'department':         _deptCtl.text.trim().isEmpty ? null : _deptCtl.text.trim(),
      'location':           _locCtl.text.trim().isEmpty ? null : _locCtl.text.trim(),
      'work_mode':          _workMode,
      'start_date':         _startCtl.text.trim(),
      'end_date':           _isCurrentJob ? null
                            : (_endCtl.text.trim().isEmpty ? null : _endCtl.text.trim()),
      'is_current_job':     _isCurrentJob,
      'description':        _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      'key_achievements':   _achieveCtl.text.trim().isEmpty ? null : _achieveCtl.text.trim(),
      'skills_used':        _skillsCtl.text.trim().isEmpty ? null : _skillsCtl.text.trim(),
      'salary_range':       _salaryCtl.text.trim().isEmpty ? null : _salaryCtl.text.trim(),
      'reference_name':     _refNameCtl.text.trim().isEmpty ? null : _refNameCtl.text.trim(),
      'reference_phone':    _refPhoneCtl.text.trim().isEmpty ? null : _refPhoneCtl.text.trim(),
      'reference_email':    _refEmailCtl.text.trim().isEmpty ? null : _refEmailCtl.text.trim(),
    };
    try {
      final api = bloc.repository.experienceApi;
      if (widget.existing?.id != null) {
        await api.update(widget.existing!.id!, payload);
      } else {
        await api.add(payload);
      }
      final fresh = await api.list();
      if (!mounted) return;
      bloc.add(ProfileExperienceReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
      navigator.pop(true);
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isSilent) return; // Phase 43.5 — silent 401 → AuthBloc redirects
      setState(() => _formError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete role?'),
        content: const Text('This experience entry will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await bloc.repository.experienceApi.delete(widget.existing!.id!);
      final fresh = await bloc.repository.experienceApi.list();
      if (!mounted) return;
      bloc.add(ProfileExperienceReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Deleted.')));
      navigator.pop(true);
    } on ApiError catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return BrandedScaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit experience' : 'Add experience'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _submitting ? null : _confirmDelete,
            ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _companyCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Company *'),
                  validator: (v) => FormValidators.required(v, label: 'Company').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Job title *'),
                  validator: (v) => FormValidators.required(v, label: 'Job title').msg,
                ),
                const SizedBox(height: 14),
                SearchableSelect<Designation>(
                  label: 'Designation',
                  items: _designations,
                  isLoading: _designationsLoading,
                  selectedItem: _designation,
                  labelOf: (d) => d.name,
                  onSelected: (d) => setState(() => _designation = d),
                ),
                const SizedBox(height: 14),
                // Phase 36.3 — stack vertically on narrow screens.
                //
                // The previous Row+Expanded layout left ~150px per cell,
                // not enough for DropdownButtonFormField's intrinsic
                // minimum (label + selected text + chevron). On Pixel-4
                // class viewports this overflowed by ~35px. Going
                // vertical avoids the squeeze entirely and matches what
                // every other long-label form field on this screen does.
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  initialValue: _employmentType,
                  decoration: const InputDecoration(labelText: 'Employment type'),
                  items: _employmentTypes.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(_titleCase(e)),
                      )).toList(),
                  onChanged: (v) => setState(() => _employmentType = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  initialValue: _workMode,
                  decoration: const InputDecoration(labelText: 'Work mode'),
                  items: _workModes.map((w) => DropdownMenuItem(
                        value: w,
                        child: Text(_titleCase(w)),
                      )).toList(),
                  onChanged: (v) => setState(() => _workMode = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _deptCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startCtl,
                        readOnly: true,
                        onTap: () => _pickDate(_startCtl),
                        decoration: const InputDecoration(
                          labelText: 'Start date *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          final r = FormValidators.required(v, label: 'Start date');
                          if (!r.ok) return r.msg;
                          return FormValidators.date(v, label: 'Start date', notFuture: true).msg;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endCtl,
                        readOnly: true,
                        enabled: !_isCurrentJob,
                        onTap: _isCurrentJob ? null : () => _pickDate(_endCtl),
                        decoration: const InputDecoration(
                          labelText: 'End date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          if (_isCurrentJob) return null;
                          final shape = FormValidators.date(v, label: 'End date');
                          if (!shape.ok) return shape.msg;
                          return FormValidators.dateRange(_startCtl.text, v).msg;
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently working here'),
                  value: _isCurrentJob,
                  onChanged: (v) => setState(() {
                    _isCurrentJob = v;
                    // Phase 38.1 — clear end-date on toggle ON.
                    if (v) _endCtl.text = '';
                  }),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtl,
                  minLines: 2, maxLines: 4,
                  inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => FormValidators.maxLen(v, 2000, label: 'Description').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _achieveCtl,
                  minLines: 2, maxLines: 4,
                  inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                  decoration: const InputDecoration(
                    labelText: 'Key achievements',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => FormValidators.maxLen(v, 2000, label: 'Achievements').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _skillsCtl,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  decoration: const InputDecoration(
                    labelText: 'Skills used',
                    helperText: 'Comma-separated, e.g. "Python, React, AWS"',
                  ),
                  validator: (v) => FormValidators.maxLen(v, 500, label: 'Skills').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _salaryCtl,
                  inputFormatters: [LengthLimitingTextInputFormatter(100)],
                  decoration: const InputDecoration(labelText: 'Salary range'),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reference contact (optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _refNameCtl,
                  inputFormatters: [LengthLimitingTextInputFormatter(120)],
                  decoration: const InputDecoration(labelText: 'Reference name'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _refPhoneCtl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [LengthLimitingTextInputFormatter(20)],
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _refEmailCtl,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [LengthLimitingTextInputFormatter(255)],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return null;
                          return FormValidators.email(v).msg;
                        },
                      ),
                    ),
                  ],
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 14),
                  _ErrorBanner(message: _formError!),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting ? null : _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: _submitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(isEdit ? 'Save changes' : 'Add role'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleCase(String s) =>
      s.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(
            message,
            style: TextStyle(
              color: theme.colorScheme.onErrorContainer,
              fontSize: 13.5,
            ),
          )),
        ],
      ),
    );
  }
}
