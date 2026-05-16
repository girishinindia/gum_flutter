// Projects section.
//
// Trimmed field set matching web Phase 24.11:
//   project_title (required), description, role_in_project,
//   organization_name, technologies_used, start_date, end_date,
//   is_ongoing, project_status, project_url, repository_url,
//   demo_url, is_featured.
//
// Server's full schema has ~47 fields but the trimmed form keeps the
// flow tight — the dropped fields are admin-managed or rarely useful.

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
import '../../domain/user_sub_resources.dart';

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Projects')),
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
          final list = state.bundle!.projects;
          if (list.isEmpty) return _empty(context);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ProjectCard(
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
            Icon(Icons.architecture_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No projects yet',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "Add side projects, client work, or open-source contributions.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add project'),
              onPressed: () => _openForm(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, UserProject? existing) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: _ProjectFormScreen(existing: existing),
      ),
    ));
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.entry, required this.onTap});
  final UserProject entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if ((entry.organizationName ?? '').isNotEmpty) entry.organizationName,
      if ((entry.roleInProject ?? '').isNotEmpty)    entry.roleInProject,
    ].whereType<String>().join(' · ');
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
          child: const Icon(Icons.architecture_outlined),
        ),
        title: Row(
          children: [
            Expanded(child: Text(entry.projectTitle, style: theme.textTheme.titleMedium)),
            if (entry.isFeatured == true)
              Icon(Icons.star, size: 18, color: theme.colorScheme.tertiary),
          ],
        ),
        subtitle: subtitle.isEmpty ? null : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: theme.textTheme.bodySmall),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Add / edit form
// ════════════════════════════════════════════════════════════════════

class _ProjectFormScreen extends StatefulWidget {
  const _ProjectFormScreen({this.existing});
  final UserProject? existing;

  @override
  State<_ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<_ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtl  = TextEditingController();
  final _descCtl   = TextEditingController();
  final _roleCtl   = TextEditingController();
  final _orgCtl    = TextEditingController();
  final _techCtl   = TextEditingController();
  final _startCtl  = TextEditingController();
  final _endCtl    = TextEditingController();
  final _urlCtl    = TextEditingController();
  final _repoCtl   = TextEditingController();
  final _demoCtl   = TextEditingController();

  String? _status;
  bool    _isOngoing  = false;
  bool    _isFeatured = false;
  bool    _submitting = false;
  String? _formError;

  static const _statuses = ['planning', 'in_progress', 'completed', 'on_hold', 'cancelled', 'abandoned'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtl.text = e.projectTitle;
      _descCtl.text  = e.description ?? '';
      _roleCtl.text  = e.roleInProject ?? '';
      _orgCtl.text   = e.organizationName ?? '';
      _techCtl.text  = e.technologiesUsed ?? '';
      _startCtl.text = e.startDate ?? '';
      _endCtl.text   = e.endDate ?? '';
      _urlCtl.text   = e.projectUrl ?? '';
      _repoCtl.text  = e.repositoryUrl ?? '';
      _demoCtl.text  = e.demoUrl ?? '';
      _status        = e.projectStatus;
      _isOngoing     = e.isOngoing ?? false;
      _isFeatured    = e.isFeatured ?? false;
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _roleCtl.dispose();
    _orgCtl.dispose();
    _techCtl.dispose();
    _startCtl.dispose();
    _endCtl.dispose();
    _urlCtl.dispose();
    _repoCtl.dispose();
    _demoCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctl) async {
    final firstDate = DateTime(1990);
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
      'project_title':     _titleCtl.text.trim(),
      'description':       _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      'role_in_project':   _roleCtl.text.trim().isEmpty ? null : _roleCtl.text.trim(),
      'organization_name': _orgCtl.text.trim().isEmpty ? null : _orgCtl.text.trim(),
      'technologies_used': _techCtl.text.trim().isEmpty ? null : _techCtl.text.trim(),
      'start_date':        _startCtl.text.trim().isEmpty ? null : _startCtl.text.trim(),
      'end_date':          _isOngoing ? null
                           : (_endCtl.text.trim().isEmpty ? null : _endCtl.text.trim()),
      'is_ongoing':        _isOngoing,
      'project_status':    _status,
      'project_url':       _urlCtl.text.trim().isEmpty ? null : _urlCtl.text.trim(),
      'repository_url':    _repoCtl.text.trim().isEmpty ? null : _repoCtl.text.trim(),
      'demo_url':          _demoCtl.text.trim().isEmpty ? null : _demoCtl.text.trim(),
      'is_featured':       _isFeatured,
    };
    try {
      final api = bloc.repository.projectsApi;
      if (widget.existing?.id != null) {
        await api.update(widget.existing!.id!, payload);
      } else {
        await api.add(payload);
      }
      final fresh = await api.list();
      if (!mounted) return;
      bloc.add(ProfileProjectsReplaced(fresh));
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
        title: const Text('Delete project?'),
        content: const Text('This project will be removed permanently.'),
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
      await bloc.repository.projectsApi.delete(widget.existing!.id!);
      final fresh = await bloc.repository.projectsApi.list();
      if (!mounted) return;
      bloc.add(ProfileProjectsReplaced(fresh));
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
        title: Text(isEdit ? 'Edit project' : 'Add project'),
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
                  controller: _titleCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Project title *'),
                  validator: (v) => FormValidators.required(v, label: 'Project title').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtl,
                  minLines: 3, maxLines: 6,
                  inputFormatters: [LengthLimitingTextInputFormatter(3000)],
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => FormValidators.maxLen(v, 3000, label: 'Description').msg,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roleCtl,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(200)],
                        decoration: const InputDecoration(labelText: 'Your role'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _orgCtl,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(200)],
                        decoration: const InputDecoration(labelText: 'Organisation'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _techCtl,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  decoration: const InputDecoration(
                    labelText: 'Technologies used',
                    helperText: 'Comma-separated, e.g. "React, TypeScript, PostgreSQL"',
                  ),
                  validator: (v) => FormValidators.maxLen(v, 500, label: 'Technologies').msg,
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
                          labelText: 'Start date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) => FormValidators.date(v, label: 'Start date', notFuture: true).msg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endCtl,
                        readOnly: true,
                        enabled: !_isOngoing,
                        onTap: _isOngoing ? null : () => _pickDate(_endCtl),
                        decoration: const InputDecoration(
                          labelText: 'End date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          if (_isOngoing) return null;
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
                  title: const Text('Ongoing'),
                  value: _isOngoing,
                  onChanged: (v) => setState(() {
                    _isOngoing = v;
                    // Phase 38.1 — clear end-date when toggling ON so a
                    // later submit cannot ship a stale value. Mirrors
                    // the education form + server invariant + DB CHECK.
                    if (v) _endCtl.text = '';
                  }),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statuses.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_titleCase(s)),
                      )).toList(),
                  onChanged: (v) => setState(() => _status = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlCtl,
                  keyboardType: TextInputType.url,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                  decoration: const InputDecoration(
                    labelText: 'Project URL',
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (v) => FormValidators.url(v, label: 'Project URL').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _repoCtl,
                  keyboardType: TextInputType.url,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                  decoration: const InputDecoration(
                    labelText: 'Repository URL',
                    prefixIcon: Icon(Icons.code),
                  ),
                  validator: (v) => FormValidators.url(v, label: 'Repository URL').msg,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _demoCtl,
                  keyboardType: TextInputType.url,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                  decoration: const InputDecoration(
                    labelText: 'Demo URL',
                    prefixIcon: Icon(Icons.play_circle_outline),
                  ),
                  validator: (v) => FormValidators.url(v, label: 'Demo URL').msg,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Feature this on my profile'),
                  value: _isFeatured,
                  onChanged: (v) => setState(() => _isFeatured = v),
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
                      : Text(isEdit ? 'Save changes' : 'Add project'),
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
