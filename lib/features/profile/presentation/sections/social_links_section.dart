// Social links section.
//
// Each entry: `social_media_id` (FK → master `social_medias.id`) +
// `profile_url` + optional `username` + `is_primary` + `is_verified`.
// The platform picker uses SearchableSelect since the platform list is
// short (~20 rows). Phase 33.2 renamed the payload fields to match the
// server's FK-driven schema — the old `{ platform, url, is_public,
// display_order }` shape never matched the live `user_social_medias`
// table and was producing "Expected number, received nan" Zod errors.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class SocialLinksSection extends StatelessWidget {
  const SocialLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Social links')),
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
          final list = state.bundle!.socialMedias;
          if (list.isEmpty) return _empty(context);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _SocialRow(
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
            Icon(Icons.link, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No social links yet',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "Add your LinkedIn, GitHub, X, or other profiles.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add link'),
              onPressed: () => _openForm(context, null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, UserSocialMedia? existing) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: _SocialFormScreen(existing: existing),
      ),
    ));
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.entry, required this.onTap});

  final UserSocialMedia entry;
  final VoidCallback    onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name  = entry.socialMedia?.name
        ?? (entry.socialMedia?.code != null ? _titleCase(entry.socialMedia!.code) : '#${entry.socialMediaId}');
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
          child: const Icon(Icons.link),
        ),
        title: Text(name, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              (entry.username ?? '').isNotEmpty ? '@${entry.username}' : entry.profileUrl,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if ((entry.username ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                entry.profileUrl,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (entry.isPrimary == true)
              Icon(Icons.star, size: 18, color: theme.colorScheme.secondary),
            if (entry.isVerified == true)
              Icon(Icons.verified, size: 18, color: theme.colorScheme.tertiary),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _titleCase(String s) =>
      s.split(RegExp(r'[_\s]')).map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

// ════════════════════════════════════════════════════════════════════
// Add / edit form
// ════════════════════════════════════════════════════════════════════

class _SocialFormScreen extends StatefulWidget {
  const _SocialFormScreen({this.existing});
  final UserSocialMedia? existing;

  @override
  State<_SocialFormScreen> createState() => _SocialFormScreenState();
}

class _SocialFormScreenState extends State<_SocialFormScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _masters  = MastersApi();
  final _urlCtl   = TextEditingController();
  final _userCtl  = TextEditingController();
  bool _isPrimary = false;

  SocialMediaPlatform? _platform;
  List<SocialMediaPlatform> _platforms = const [];
  bool _platformsLoading = false;
  bool _submitting       = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _urlCtl.text  = e.profileUrl;
      _userCtl.text = e.username ?? '';
      _isPrimary    = e.isPrimary ?? false;
      // The joined `social_media` row already gives us the platform; we
      // try to resolve to the same instance from the master list after
      // load so the SearchableSelect highlights it.
      if (e.socialMedia != null) _platform = e.socialMedia;
    }
    _loadPlatforms();
  }

  Future<void> _loadPlatforms() async {
    setState(() => _platformsLoading = true);
    try {
      final rows = await _masters.listSocialMediaPlatforms();
      if (!mounted) return;
      setState(() {
        _platforms = rows;
        if (widget.existing != null) {
          final id = widget.existing!.socialMediaId;
          final match = rows.where((p) => p.id == id).cast<SocialMediaPlatform?>().firstWhere(
            (p) => p != null, orElse: () => null);
          if (match != null) _platform = match;
        }
      });
    } catch (_) {/* leave empty */} finally {
      if (mounted) setState(() => _platformsLoading = false);
    }
  }

  @override
  void dispose() {
    _urlCtl.dispose();
    _userCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_platform == null) {
      setState(() => _formError = 'Please pick a platform.');
      return;
    }
    setState(() => _submitting = true);
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Bug 5 fix: payload now matches the server schema exactly —
    // `social_media_id` (FK numeric) + `profile_url`, `is_primary`
    // (replacing the old `platform` code + `url` + `is_public`).
    final payload = <String, dynamic>{
      'social_media_id': _platform!.id,
      'profile_url':     _urlCtl.text.trim(),
      'username':        _userCtl.text.trim().isEmpty ? null : _userCtl.text.trim(),
      'is_primary':      _isPrimary,
    };
    try {
      final api = bloc.repository.socialMediaApi;
      if (widget.existing?.id != null) {
        await api.update(widget.existing!.id!, payload);
      } else {
        await api.add(payload);
      }
      final fresh = await api.list();
      if (!mounted) return;
      bloc.add(ProfileSocialMediasReplaced(fresh));
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
        title: const Text("Remove link?"),
        content: const Text('This social link will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await bloc.repository.socialMediaApi.delete(widget.existing!.id!);
      final fresh = await bloc.repository.socialMediaApi.list();
      if (!mounted) return;
      bloc.add(ProfileSocialMediasReplaced(fresh));
      messenger.showSnackBar(const SnackBar(content: Text('Removed.')));
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
        title: Text(isEdit ? 'Edit social link' : 'Add social link'),
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
                SearchableSelect<SocialMediaPlatform>(
                  label: 'Platform',
                  items: _platforms,
                  isLoading: _platformsLoading,
                  selectedItem: _platform,
                  labelOf: (p) => p.name,
                  onSelected: (p) => setState(() => _platform = p),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlCtl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                  decoration: InputDecoration(
                    labelText: 'URL *',
                    prefixIcon: const Icon(Icons.link),
                    hintText: _platform?.placeholder ?? 'https://…',
                  ),
                  validator: (v) {
                    final r = FormValidators.required(v, label: 'URL');
                    if (!r.ok) return r.msg;
                    return FormValidators.url(v).msg;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _userCtl,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(300)],
                  decoration: const InputDecoration(
                    labelText: 'Username (optional)',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) => FormValidators.username(v).msg,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Primary link'),
                  subtitle: const Text('Highlighted on your profile as the main one.'),
                  value: _isPrimary,
                  onChanged: (v) => setState(() => _isPrimary = v),
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
                      : Text(isEdit ? 'Save changes' : 'Add link'),
                ),
              ],
            ),
          ),
        ),
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
