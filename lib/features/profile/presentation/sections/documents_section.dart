// Documents section.
//
// List of user-documents with verification status pills (pending /
// under_review / verified / rejected / expired / reupload). Add via
// type → document cascade against the masters API:
//
//   1. /document-types        → top-level category
//   2. /documents?type=X      → specific document within that type
//
// Document number validator routes by name (PAN / Aadhaar / passport
// → format checks; everything else → max-length). Multipart upload
// supports images (image pipeline) and PDFs (raw passthrough on the
// server). Self-service users can only delete — admin owns the
// verification_status / rejection_reason / admin_notes fields.

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
import '../../data/profile_api.dart' show EducationCertFile;
import '../../domain/master_models.dart';
import '../../domain/user_sub_resources.dart';
import '../widgets/searchable_select.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
        onPressed: () => _openForm(context, null),
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = state.bundle!.documents;
          if (list.isEmpty) return _empty(context);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _DocumentRow(
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
            Icon(Icons.folder_open, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No documents uploaded',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "KYC, certificates, and government IDs. We'll verify them after upload.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload a document'),
              onPressed: () => _openForm(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, UserDocument? existing) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: _DocumentFormScreen(existing: existing),
      ),
    ));
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.entry, required this.onTap});

  final UserDocument entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeName = entry.documentType?.name ?? '';
    final docName  = entry.document?.name     ?? '';
    final title    = docName.isNotEmpty ? docName : (typeName.isNotEmpty ? typeName : 'Document');
    final subtitle = [
      if (typeName.isNotEmpty && typeName != title) typeName,
      if ((entry.documentNumber ?? '').isNotEmpty)  entry.documentNumber,
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
          child: const Icon(Icons.description_outlined),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 6),
            _StatusPill(status: entry.verificationStatus ?? 'pending'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bg, fg, icon) = switch (status) {
      'verified'     => ('Verified',       Colors.green.shade100, Colors.green.shade800,  Icons.verified),
      'rejected'     => ('Rejected',       Colors.red.shade100,   Colors.red.shade800,    Icons.cancel_outlined),
      'under_review' => ('Under review',   Colors.blue.shade100,  Colors.blue.shade800,   Icons.search),
      'expired'      => ('Expired',        Colors.amber.shade100, Colors.amber.shade900,  Icons.timer_off),
      'reupload'     => ('Re-upload',      Colors.purple.shade100,Colors.purple.shade800, Icons.refresh),
      _              => ('Pending',        theme.colorScheme.surfaceContainerHighest,
                                            theme.colorScheme.onSurface,                 Icons.schedule),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Add / edit form
// ════════════════════════════════════════════════════════════════════

class _DocumentFormScreen extends StatefulWidget {
  const _DocumentFormScreen({this.existing});
  final UserDocument? existing;

  @override
  State<_DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<_DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _masters = MastersApi();

  final _numberCtl = TextEditingController();
  final _issueCtl  = TextEditingController();
  final _expiryCtl = TextEditingController();

  DocumentType?  _type;
  MasterDocument? _doc;

  List<DocumentType> _types = const [];
  bool _typesLoading = false;

  final Map<int, List<MasterDocument>> _docsByType = {};
  final Set<int> _docsLoadingFor = {};

  EducationCertFile? _newFile;
  bool _submitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _numberCtl.text = e.documentNumber ?? '';
      _issueCtl.text  = e.issueDate ?? '';
      _expiryCtl.text = e.expiryDate ?? '';
      if (e.documentType != null) {
        _type = e.documentType;
      } else if (e.documentTypeId > 0) {
        _type = DocumentType(id: e.documentTypeId, name: '#${e.documentTypeId}');
      }
      if (e.document != null) {
        _doc = e.document;
      } else if (e.documentId != null) {
        _doc = MasterDocument(id: e.documentId!, documentTypeId: e.documentTypeId, name: '#${e.documentId}');
      }
    }
    _loadTypes();
    if (_type != null) _ensureDocsFor(_type!.id);
  }

  Future<void> _loadTypes() async {
    setState(() => _typesLoading = true);
    try {
      final rows = await _masters.listDocumentTypes();
      if (!mounted) return;
      setState(() {
        _types = rows;
        if (_type != null) {
          final real = rows.where((t) => t.id == _type!.id).cast<DocumentType?>().firstWhere(
            (t) => t != null, orElse: () => null);
          if (real != null) _type = real;
        }
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _typesLoading = false);
    }
  }

  Future<void> _ensureDocsFor(int typeId) async {
    if (_docsByType[typeId] != null || _docsLoadingFor.contains(typeId)) return;
    setState(() => _docsLoadingFor.add(typeId));
    try {
      final rows = await _masters.listMasterDocuments(typeId);
      if (!mounted) return;
      setState(() {
        _docsByType[typeId] = rows;
        if (_doc != null) {
          final real = rows.where((d) => d.id == _doc!.id).cast<MasterDocument?>().firstWhere(
            (d) => d != null, orElse: () => null);
          if (real != null) _doc = real;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _docsByType[typeId] = const []);
    } finally {
      if (mounted) setState(() => _docsLoadingFor.remove(typeId));
    }
  }

  @override
  void dispose() {
    _numberCtl.dispose();
    _issueCtl.dispose();
    _expiryCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctl, {bool allowFuture = false}) async {
    final firstDate = DateTime(1950);
    final lastDate  = allowFuture ? DateTime(DateTime.now().year + 30) : DateTime.now();
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

  Future<void> _pickFile() async {
    // Capture handles before any await so we never reach across an
    // async gap onto the BuildContext.
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
        setState(() => _newFile = EducationCertFile(
              path: x.path, filename: x.name, mimeType: x.mimeType));
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
        );
        if (!mounted) return;
        final f = result?.files.single;
        if (f == null || f.path == null) return;
        setState(() => _newFile = EducationCertFile(path: f.path!, filename: f.name));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't pick file: $e")));
    }
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_type == null) {
      setState(() => _formError = 'Please pick a document type.');
      return;
    }
    if (_doc == null) {
      setState(() => _formError = 'Please pick a document.');
      return;
    }
    if (widget.existing == null && _newFile == null) {
      setState(() => _formError = 'Please upload a file.');
      return;
    }
    setState(() => _submitting = true);
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final payload = <String, dynamic>{
      'document_type_id': _type!.id,
      'document_id':      _doc!.id,
      'document_number':  _numberCtl.text.trim().isEmpty ? null : _numberCtl.text.trim(),
      'issue_date':       _issueCtl.text.trim().isEmpty ? null : _issueCtl.text.trim(),
      'expiry_date':      _expiryCtl.text.trim().isEmpty ? null : _expiryCtl.text.trim(),
    };
    try {
      final api = bloc.repository.documentsApi;
      if (widget.existing?.id != null) {
        await api.update(widget.existing!.id!, payload, file: _newFile);
      } else {
        await api.add(payload, file: _newFile);
      }
      final fresh = await api.list();
      if (!mounted) return;
      bloc.add(ProfileDocumentsReplaced(fresh));
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
        title: const Text('Delete document?'),
        content: const Text('This document will be removed permanently.'),
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
      await bloc.repository.documentsApi.delete(widget.existing!.id!);
      final fresh = await bloc.repository.documentsApi.list();
      if (!mounted) return;
      bloc.add(ProfileDocumentsReplaced(fresh));
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
    final docsForType = _type == null ? const <MasterDocument>[] : (_docsByType[_type!.id] ?? const []);
    final docsLoading = _type != null && _docsLoadingFor.contains(_type!.id);
    final hasExistingFile = (widget.existing?.file ?? '').isNotEmpty;
    return BrandedScaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit document' : 'Upload document'),
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
                if (isEdit && (widget.existing?.verificationStatus ?? 'pending') != 'pending')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _StatusBanner(
                      status: widget.existing!.verificationStatus!,
                      reason: widget.existing!.rejectionReason,
                    ),
                  ),
                SearchableSelect<DocumentType>(
                  label: 'Document type',
                  items: _types,
                  isLoading: _typesLoading,
                  selectedItem: _type,
                  labelOf: (t) => t.name.startsWith('#') ? 'Loading…' : t.name,
                  onSelected: (t) {
                    setState(() {
                      _type = t;
                      _doc  = null;
                    });
                    _ensureDocsFor(t.id);
                  },
                ),
                const SizedBox(height: 14),
                SearchableSelect<MasterDocument>(
                  label: 'Document',
                  items: docsForType,
                  isLoading: docsLoading,
                  selectedItem: _doc,
                  enabled: _type != null,
                  labelOf: (d) => d.name.startsWith('#') ? 'Loading…' : d.name,
                  onSelected: (d) => setState(() => _doc = d),
                  placeholder: _type == null ? 'Pick a type first' : 'Select document',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _numberCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(200)],
                  decoration: const InputDecoration(labelText: 'Document number'),
                  validator: (v) => FormValidators.documentNumber(v, _doc?.name).msg,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _issueCtl,
                        readOnly: true,
                        onTap: () => _pickDate(_issueCtl),
                        decoration: const InputDecoration(
                          labelText: 'Issued on',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) => FormValidators.date(v, label: 'Issue date', notFuture: true).msg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _expiryCtl,
                        readOnly: true,
                        onTap: () => _pickDate(_expiryCtl, allowFuture: true),
                        decoration: const InputDecoration(
                          labelText: 'Expires on',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (v) {
                          final shape = FormValidators.date(v, label: 'Expiry date');
                          if (!shape.ok) return shape.msg;
                          return FormValidators.dateRange(_issueCtl.text, v,
                              startLabel: 'Issue date', endLabel: 'Expiry date').msg;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _filePicker(hasExistingFile),
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
                      : Text(isEdit ? 'Save changes' : 'Upload'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filePicker(bool hasExistingFile) {
    final theme = Theme.of(context);
    String label;
    if (_newFile != null) {
      label = 'New: ${_newFile!.filename}';
    } else if (hasExistingFile) {
      label = 'File on server';
    } else {
      label = 'No file selected';
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
              Icon(Icons.attach_file, color: theme.colorScheme.primary),
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
                label: Text(hasExistingFile || _newFile != null ? 'Replace' : 'Upload'),
                onPressed: _submitting ? null : _pickFile,
              ),
              if (_newFile != null)
                TextButton(
                  onPressed: _submitting ? null : () => setState(() => _newFile = null),
                  child: const Text('Discard new'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.reason});
  final String status;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRejected = status == 'rejected';
    final isVerified = status == 'verified';
    final isUnder    = status == 'under_review';
    final isExpired  = status == 'expired';
    final color = isRejected ? theme.colorScheme.errorContainer
                : isVerified ? Colors.green.shade100
                : isUnder    ? Colors.blue.shade100
                : isExpired  ? Colors.amber.shade100
                : theme.colorScheme.surfaceContainerHighest;
    final onColor = isRejected ? theme.colorScheme.onErrorContainer
                  : isVerified ? Colors.green.shade900
                  : isUnder    ? Colors.blue.shade900
                  : isExpired  ? Colors.amber.shade900
                  : theme.colorScheme.onSurface;
    final icon = isRejected ? Icons.cancel_outlined
              : isVerified ? Icons.verified
              : isUnder    ? Icons.search
              : isExpired  ? Icons.timer_off
              : Icons.info_outline;
    final title = isRejected ? 'Rejected'
                : isVerified ? 'Verified'
                : isUnder    ? 'Under review'
                : isExpired  ? 'Expired'
                : 'Status: $status';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: onColor, fontWeight: FontWeight.w700)),
                if ((reason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(reason!, style: TextStyle(color: onColor, fontSize: 13.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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
            style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13.5),
          )),
        ],
      ),
    );
  }
}
