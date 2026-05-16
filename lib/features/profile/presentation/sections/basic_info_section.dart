// Basic info section — fully functional, demonstrates the
// section-screen pattern Phases E–G will follow:
//
//   1. BlocBuilder on ProfileBloc to source initial values.
//   2. Local controllers + form key for editing.
//   3. On save:
//        • display_name → PATCH /users/me      (UsersApi via AuthRepository.updateMe)
//        • headline/bio/slug/is_public/DOB/gender → PUT /user-profiles/me
//      Both succeed independently so we can show a sensible error
//      if only one fails.
//   4. Dispatch ProfileProfileUpdated + AuthUserRefreshed to keep
//      both blocs' caches fresh.
//
// Validation mirrors the web BasicInfoCard (display_name <= 100,
// headline <= 200, bio <= 2000, slug <= 100, DOB age 13–120).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../domain/user_profile.dart';

class BasicInfoSection extends StatefulWidget {
  const BasicInfoSection({super.key});

  @override
  State<BasicInfoSection> createState() => _BasicInfoSectionState();
}

class _BasicInfoSectionState extends State<BasicInfoSection> {
  final _formKey       = GlobalKey<FormState>();
  final _displayNameCtl = TextEditingController();
  final _headlineCtl    = TextEditingController();
  final _bioCtl         = TextEditingController();
  final _slugCtl        = TextEditingController();
  final _dobCtl         = TextEditingController();
  String? _gender;
  bool    _isPublic     = true;
  bool    _submitting   = false;
  bool    _hydrated     = false;
  String? _formError;

  // Bug 3c — avatar uploader state.
  //
  // `_pickedAvatarPath` is set the moment the user picks an image; we
  // show it as a local preview while the multipart PUT is in flight,
  // then drop it once the server returns the persisted CDN URL via
  // ProfileProfileUpdated. `_avatarUploading` gates the picker so the
  // user can't double-tap.
  String? _pickedAvatarPath;
  bool    _avatarUploading = false;
  String? _avatarError;

  @override
  void dispose() {
    _displayNameCtl.dispose();
    _headlineCtl.dispose();
    _bioCtl.dispose();
    _slugCtl.dispose();
    _dobCtl.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile profile, AuthState auth) {
    if (_hydrated) return;
    _displayNameCtl.text = (auth.user?.displayName ?? profile.displayName ?? '');
    _headlineCtl.text    = profile.headline ?? '';
    _bioCtl.text         = profile.bio ?? '';
    _slugCtl.text        = profile.slug ?? '';
    _dobCtl.text         = profile.dateOfBirth ?? '';
    _gender              = profile.gender;
    _isPublic            = profile.isPublic ?? true;
    _hydrated            = true;
  }

  Future<void> _pickAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pick from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 88,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _avatarError = "Couldn't open picker: $e");
      return;
    }
    if (picked == null || !mounted) return;
    // Capture local copies — Dart's flow analysis doesn't promote
    // through `setState` closures, and we read these again post-await.
    final pickedPath     = picked.path;
    final pickedName     = picked.name;
    final pickedMimeType = picked.mimeType;

    setState(() {
      _pickedAvatarPath = pickedPath;
      _avatarUploading  = true;
      _avatarError      = null;
    });

    final profileBloc = context.read<ProfileBloc>();
    try {
      final updated = await profileBloc.repository.updateProfileWithImage(
        profileImagePath:     pickedPath,
        profileImageFilename: pickedName,
        profileImageMimeType: pickedMimeType,
      );
      if (!mounted) return;
      profileBloc.add(ProfileProfileUpdated(updated));
      messenger.showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _avatarError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _avatarError = "Couldn't upload photo. Please try again.");
    } finally {
      if (mounted) setState(() {
        _avatarUploading = false;
        // Drop the local preview — the bundle.profile.profileImageUrl
        // now points at the persisted CDN URL.
        _pickedAvatarPath = null;
      });
    }
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dobCtl.text) ?? DateTime(DateTime.now().year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 120),
      lastDate:  DateTime.now(),
    );
    if (picked != null) {
      _dobCtl.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final authBloc    = context.read<AuthBloc>();
    final profileBloc = context.read<ProfileBloc>();
    final messenger   = ScaffoldMessenger.of(context);

    final newDisplay = _displayNameCtl.text.trim();
    final originalDisplay = authBloc.state.user?.displayName ?? '';

    try {
      // (1) display_name → /users/me (only when it changed)
      if (newDisplay != originalDisplay) {
        await authBloc.repository.updateMe(displayName: newDisplay);
      }

      // (2) everything else → /user-profiles/me (PUT == upsert)
      final patch = <String, dynamic>{
        'display_name':  newDisplay.isEmpty ? null : newDisplay,
        'headline':      _headlineCtl.text.trim().isEmpty ? null : _headlineCtl.text.trim(),
        'bio':           _bioCtl.text.trim().isEmpty ? null : _bioCtl.text.trim(),
        'slug':          _slugCtl.text.trim().isEmpty ? null : _slugCtl.text.trim(),
        'is_public':     _isPublic,
        'date_of_birth': _dobCtl.text.trim().isEmpty ? null : _dobCtl.text.trim(),
        'gender':        _gender,
      };
      final updated = await profileBloc.repository.updateProfile(patch);

      if (!mounted) return;
      profileBloc.add(ProfileProfileUpdated(updated));
      // AuthBloc cache stays fresh via the repo's sessionChanges stream
      // (auth_bloc.dart subscribes in Phase A's wiring). No manual
      // dispatch here — AuthUser.copyWith can't clear nullable fields,
      // so the stream path is the only correct way to surface a
      // cleared display_name to the cached AuthUser.

      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _formError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Basic information')),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.isLoaded || state.bundle == null) {
            return Center(
              child: Text(state.errorMessage ?? 'Failed to load profile'),
            );
          }
          _hydrate(state.bundle!.profile, context.read<AuthBloc>().state);
          final avatarUrl = state.bundle!.profile.profileImageUrl;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AvatarRow(
                      avatarUrl:      avatarUrl,
                      pickedFilePath: _pickedAvatarPath,
                      busy:           _avatarUploading,
                      error:          _avatarError,
                      displayName:    _displayNameCtl.text,
                      onPick:         _pickAvatar,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _displayNameCtl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        helperText: 'Shown to other learners on your public profile.',
                      ),
                      validator: (v) => FormValidators.maxLen(v, 100, label: 'Display name').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _headlineCtl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(200)],
                      decoration: const InputDecoration(
                        labelText: 'Headline',
                        helperText: 'One-liner — e.g. "Senior Data Scientist at Acme".',
                      ),
                      validator: (v) => FormValidators.maxLen(v, 200, label: 'Headline').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bioCtl,
                      minLines: 3,
                      maxLines: 6,
                      inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                      decoration: const InputDecoration(
                        labelText: 'About / bio',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => FormValidators.maxLen(v, 2000, label: 'Bio').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _slugCtl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._\-]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Public URL handle',
                        helperText: 'Letters, digits, dots, hyphens. Used in your profile URL.',
                      ),
                      validator: (v) => FormValidators.username(v).msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dobCtl,
                      readOnly: true,
                      onTap: _pickDob,
                      decoration: const InputDecoration(
                        labelText: 'Date of birth',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (v) => FormValidators.age(v).msg,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'male',              child: Text('Male')),
                        DropdownMenuItem(value: 'female',            child: Text('Female')),
                        DropdownMenuItem(value: 'other',             child: Text('Other')),
                        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Public profile'),
                      subtitle: const Text('Allow others to find and view your profile.'),
                      value: _isPublic,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, size: 18,
                                color: theme.colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                              _formError!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 13.5,
                              ),
                            )),
                          ],
                        ),
                      ),
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
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// _AvatarRow — circular avatar + camera badge that opens the picker.
//
// The avatar source priority is:
//   1. `pickedFilePath` — local file just chosen by the user (shown
//      instantly so they get feedback while the upload is in flight).
//   2. `avatarUrl` — the persisted CDN URL from UserProfile.
//   3. Initial-letter fallback — first letter of `displayName`.
//
// `busy` darkens the avatar + shows a spinner over the badge while the
// multipart PUT is mid-flight. `error` renders an inline rose message
// below the row.
// ════════════════════════════════════════════════════════════════════

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    required this.avatarUrl,
    required this.pickedFilePath,
    required this.busy,
    required this.error,
    required this.displayName,
    required this.onPick,
  });

  final String?     avatarUrl;
  final String?     pickedFilePath;
  final bool        busy;
  final String?     error;
  final String      displayName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = displayName.trim().isEmpty
        ? '?'
        : displayName.trim()[0].toUpperCase();

    Widget avatar;
    if (pickedFilePath != null) {
      avatar = ClipOval(
        child: Image.file(
          File(pickedFilePath!),
          width: 96, height: 96, fit: BoxFit.cover,
        ),
      );
    } else if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          avatarUrl!,
          width: 96, height: 96, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialAvatar(theme, initial),
        ),
      );
    } else {
      avatar = _initialAvatar(theme, initial);
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Opacity(opacity: busy ? 0.65 : 1.0, child: avatar),
            Material(
              shape: const CircleBorder(),
              color: theme.colorScheme.primaryContainer,
              elevation: 1,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: busy ? null : onPick,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: busy
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Icon(Icons.camera_alt_outlined,
                          size: 18, color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _initialAvatar(ThemeData theme, String initial) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      child: Text(
        initial,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
