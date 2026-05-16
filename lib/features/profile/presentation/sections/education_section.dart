// Education section.
//
// Layout: list of UserEducation entries + floating "Add" button. Tap
// a row to edit. The form is a pushed full-screen route (cleaner than
// a modal sheet for the number of fields).
//
// Multipart: optional certificate file via image_picker (for photos)
// or file_picker (for PDFs). The API layer (EducationApi.add /
// .update) builds the FormData with our `EducationCertFile` shim.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../data/masters_api.dart';
import '../../data/profile_api.dart';
import '../../domain/master_models.dart';
import '../../domain/user_sub_resources.dart';
import '../widgets/searchable_select.dart';

class EducationSection extends StatelessWidget {
  const EducationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Education')),
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
          final list = state.bundle!.education;
          if (list.isEmpty) {
            return _EmptyState(onAdd: () => _openForm(context, null));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _EducationCard(
              entry: list[i],
              onTap: () => _openForm(context, list[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, UserEducation? existing) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: _EducationFormScreen(existing: existing),
      ),
    ));
  }
}

class _EducationCard extends StatelessWidget {
  const _EducationCard({required this.entry, required this.onTap});
  final UserEducation entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelName = entry.educationLevel?.name ?? 'Education';
    final dateRange = _formatRange(entry.startDate, entry.endDate, entry.isCurrentlyStudying ?? false);
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
          child: const Icon(Icons.school_outlined),
        ),
        title: Text(entry.institutionName, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              [levelName, if ((entry.fieldOfStudy ?? '').isNotEmpty) entry.fieldOfStudy].whereType<String>().join(' · '),
              style: theme.textTheme.bodySmall,
            ),
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

  String _formatRange(String? start, String? end, bool ongoing) {
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No education entries yet',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Add your schools, degrees, and certifications. '
              'You can upload a certificate for each entry.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add entry'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Add / edit form
// ════════════════════════════════════════════════════════════════════

class _EducationFormScreen extends StatefulWidget {
  const _EducationFormScreen({this.existing});
  final UserEducation? existing;

  @override
  State<_EducationFormScreen> createState() => _EducationFormScreenState();
}

class _EducationFormScreenState extends State<_EducationFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _masters  = MastersApi();

  final _institutionCtl = TextEditingController();
  final _boardCtl       = TextEditingController();
  final _fieldCtl       = TextEditingController();
  final _specCtl        = TextEditingController();
  final _gradeCtl       = TextEditingController();
  final _descCtl        = TextEditingController();
  final _startCtl       = TextEditingController();
  final _endCtl         = TextEditingController();

  String? _gradeType;
  bool    _isCurrentlyStudying  = false;
  bool    _isHighestQualification = false;
  EducationLevel? _level;

  EducationCertFile? _newCertFile;
  bool _clearExistingCert = false;

  List<EducationLevel> _levels = const [];
  bool _levelsLoading = false;
  bool _submitting    = false;
  String? _formError;

  static const _gradeTypes = ['percentage', 'cgpa', 'gpa', 'grade', 'pass_fail', 'other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _institutionCtl.text = e.institutionName;
      _boardCtl.text       = e.boardOrUniversity ?? '';
      _fieldCtl.text       = e.fieldOfStudy ?? '';
      _specCtl.text        = e.specialization ?? '';
      _gradeCtl.text       = e.gradeOrPercentage ?? '';
      _descCtl.text        = e.description ?? '';
      _startCtl.text       = e.startDate ?? '';
      _endCtl.text         = e.endDate ?? '';
      _gradeType           = e.gradeType;
      _isCurrentlyStudying = e.isCurrentlyStudying ?? false;
      _isHighestQualification = e.isHighestQualification ?? false;
      _level               = e.educationLevel != null
          ? EducationLevel(id: e.educationLevel!.id, name: e.educationLevel!.name)
          : (e.educationLevelId > 0
              ? EducationLevel(id: e.educationLevelId, name: '#${e.educationLevelId}')
              : null);
    }
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() => _levelsLoading = true);
    try {
      final rows = await _masters.listEducationLevels();
      if (!mounted) return;
      setState(() {
        _levels = rows;
        if (_level != null) {
          final real = rows.where((l) => l.id == _level!.id).cast<EducationLevel?>().firstWhere(
            (l) => l != null, orElse: () => null);
          if (real != null) _level = real;
        }
      });
    } catch (_) {
      // Leave levels empty.
    } finally {
      if (mounted) setState(() => _levelsLoading = false);
    }
  }

  @override
  void dispose() {
    _institutionCtl.dispose();
    _boardCtl.dispose();
    _fieldCtl.dispose();
    _specCtl.dispose();
    _gradeCtl.dispose();
    _descCtl.dispose();
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctl, {bool allowFuture = false}) async {
    final firstDate = DateTime(1950);
    final lastDate  = allowFuture ? DateTime(DateTime.now().year + 10) : DateTime.now();
    var initial = DateTime.tryParse(ctl.text) ?? DateTime.now();
    // `showDatePicker` throws if initial is outside [first, last] — clamp.
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

  Future<void> _pickCertFile() async {
    final messenger = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(sheetCtx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetCtx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.file_present_outlined),
              title: const Text('Pick a PDF / file'),
              onTap: () => Navigator.pop(sheetCtx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'gallery' || action == 'camera') {
        final picker = ImagePicker();
        final x = await picker.pickImage(
          source: action == 'gallery' ? ImageSource.gallery : ImageSource.camera,
          maxWidth: 2400,
          imageQuality: 85,
        );
        if (!mounted || x == null) return;
        setState(() {
          _newCertFile = EducationCertFile(
            path: x.path,
            filename: x.name,
            mimeType: x.mimeType,
          );
          _clearExistingCert = false;
        });
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
        );
        if (!mounted) return;
        final f = result?.files.single;
        if (f == null || f.path == null) return;
        setState(() {
          _newCertFile = EducationCertFile(
            path: f.path!,
            filename: f.name,
          );
          _clearExistingCert = false;
        });
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't pick file: $e")));
    }
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_level == null) {
      setState(() => _formError = 'Please pick an education level.');
      return;
    }
    setState(() => _submitting = true);

    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final payload = <String, dynamic>{
      'education_level_id':       _level!.id,
      'institution_name':         _institutionCtl.text.trim(),
      'board_or_university':      _boardCtl.text.trim().isEmpty ? null : _boardCtl.text.trim(),
      'field_of_study':           _fieldCtl.text.trim().isEmpty ? null : _fieldCtl.text.trim(),
      'specialization':           _specCtl.text.trim().isEmpty ? null : _specCtl.text.trim(),
      'grade_or_percentage':      _gradeCtl.text.trim().isEmpty ? null : _gradeCtl.text.trim(),
      'grade_type':               _gradeType,
      'start_date':               _startCtl.text.trim().isEmpty ? null : _startCtl.text.trim(),
      'end_date':                 _isCurrentlyStudying ? null
                                  : (_endCtl.text.trim().isEmpty ? null : _endCtl.text.trim()),
      'is_currently_studying':    _isCurrentlyStudying,
      'is_highest_qualification': _isHighestQualification,
      'description':              _descCtl.text.trim().isEmpty ? null : _descCtl.text.trim(),
      if (_clearExistingCert) 'certificate_url': null,
    };

    try {
      final api = bloc.repository.educationApi;
      if (widget.existing?.id != null) {
        await api.update(widget.existing!.id!, payload, certificate: _newCertFile);
      } else {
        await api.add(payload, certificate: _newCertFile);
      }
      final fresh = await api.list();
      if (!mounted) return;
      bloc.add(ProfileEducationReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
      navigator.pop(true);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
      // Bug 3b fix: pull a fresh list so the section view behind this
      // form reflects what's actually persisted. The bloc only updates
      // on success above, but a partial save could leave the existing
      // row's dates in a stale state — re-fetching is cheap insurance.
      try {
        final refreshed = await bloc.repository.educationApi.list();
        if (!mounted) return;
        bloc.add(ProfileEducationReplaced(refreshed));
      } catch (_) {/* keep the original error message */}
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
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This education entry will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await bloc.repository.educationApi.delete(widget.existing!.id!);
      final fresh = await bloc.repository.educationApi.list();
      if (!mounted) return;
      bloc.add(ProfileEducationReplaced(fresh));
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
    final existingCertUrl = widget.existing?.certificateUrl;
    final hasExistingCert = (existingCertUrl ?? '').isNotEmpty && !_clearExistingCert;
    return BrandedScaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit education' : 'Add education'),
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
                SearchableSelect<EducationLevel>(
                  label: 'Level',
                  items: _levels,
                  isLoading: _levelsLoading,
                  selectedItem: _level,
                  labelOf: (l) => l.name,
                  onSelected: (l) => setState(() => _level = l),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _institutionCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Institution / school *'),
                  validator: (v) {
                    final r = FormValidators.required(v, label: 'Institution');
                    return r.ok ? FormValidators.maxLen(v, 200, label: 'Institution').msg : r.msg;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _boardCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Board or university'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fieldCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Field of study'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Specialization'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gradeCtl,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(100)],
                        decoration: const InputDecoration(labelText: 'Grade / score'),
                        validator: (v) => FormValidators.grade(v, _gradeType).msg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gradeType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _gradeTypes.map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(_titleCase(g)),
                            )).toList(),
                        onChanged: (v) => setState(() => _gradeType = v),
                      ),
                    ),
                  ],
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
                        enabled: !_isCurrentlyStudying,
                        onTap: _isCurrentlyStudying ? null : () => _pickDate(_endCtl, allowFuture: true),
                        decoration: const InputDecoration(
                          labelText: 'End date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          if (_isCurrentlyStudying) return null;
                          final shape = FormValidators.date(v, label: 'End date');
                          if (!shape.ok) return shape.msg;
                          return FormValidators.dateRange(_startCtl.text, v).msg;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently studying'),
                  value: _isCurrentlyStudying,
                  onChanged: (v) => setState(() => _isCurrentlyStudying = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('This is my highest qualification'),
                  value: _isHighestQualification,
                  onChanged: (v) => setState(() => _isHighestQualification = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtl,
                  minLines: 2,
                  maxLines: 4,
                  inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => FormValidators.maxLen(v, 2000, label: 'Description').msg,
                ),
                const SizedBox(height: 18),
                _certPicker(hasExistingCert, existingCertUrl),
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
                      : Text(isEdit ? 'Save changes' : 'Add entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _certPicker(bool hasExistingCert, String? existingUrl) {
    final theme = Theme.of(context);
    String label;
    if (_newCertFile != null) {
      label = 'New: ${_newCertFile!.filename}';
    } else if (hasExistingCert) {
      label = 'Certificate on file';
    } else {
      label = 'No certificate uploaded';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(hasExistingCert || _newCertFile != null ? 'Replace' : 'Upload'),
                onPressed: _submitting ? null : _pickCertFile,
              ),
              if (_newCertFile != null)
                TextButton(
                  onPressed: _submitting ? null : () => setState(() => _newCertFile = null),
                  child: const Text('Discard new'),
                ),
              if (hasExistingCert && _newCertFile == null)
                TextButton(
                  onPressed: _submitting ? null : () => setState(() => _clearExistingCert = true),
                  child: const Text('Remove certificate'),
                ),
              if (_clearExistingCert)
                TextButton(
                  onPressed: _submitting ? null : () => setState(() => _clearExistingCert = false),
                  child: const Text('Keep certificate'),
                ),
            ],
          ),
        ],
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
