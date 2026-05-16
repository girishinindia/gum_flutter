// Contact section.
//
// Email + mobile are read-only here because changing them is a
// security operation (Phase G / Security: requires OTP). We surface
// them prominently with a "Change" CTA that links to the Security
// section once it ships.
//
// Emergency contact (name + mobile + relation) saves via PUT
// /user-profiles/me. Relation is a free-text dropdown matching the
// web side's options.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../domain/user_profile.dart';

class ContactSection extends StatefulWidget {
  const ContactSection({super.key});

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtl      = TextEditingController();
  final _mobileCtl    = TextEditingController();
  String? _relation;
  bool    _hydrated   = false;
  bool    _submitting = false;
  String? _formError;

  static const _relations = <String>[
    'parent', 'spouse', 'sibling', 'child', 'friend',
    'relative', 'colleague', 'guardian', 'other',
  ];

  @override
  void dispose() {
    _nameCtl.dispose();
    _mobileCtl.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    if (_hydrated) return;
    _nameCtl.text   = p.emergencyContactName ?? '';
    _mobileCtl.text = p.emergencyContactMobile ?? '';
    _relation       = p.emergencyContactRelation;
    _hydrated       = true;
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final profileBloc = context.read<ProfileBloc>();
    final messenger   = ScaffoldMessenger.of(context);

    try {
      final patch = <String, dynamic>{
        'emergency_contact_name':     _nameCtl.text.trim().isEmpty ? null : _nameCtl.text.trim(),
        'emergency_contact_mobile':   _mobileCtl.text.trim().isEmpty ? null : _mobileCtl.text.trim(),
        'emergency_contact_relation': _relation,
      };
      final updated = await profileBloc.repository.updateProfile(patch);
      if (!mounted) return;
      profileBloc.add(ProfileProfileUpdated(updated));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Contact')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _hydrate(state.bundle!.profile);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _readOnlyIdentitySection(context),
                    const SizedBox(height: 24),
                    Text(
                      'Emergency contact',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => FormValidators.maxLen(v, 120, label: 'Name').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _mobileCtl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mobile (10 digits)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+91 ',
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return null; // optional
                        return FormValidators.mobile(s).msg;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _relation,
                      decoration: const InputDecoration(labelText: 'Relation'),
                      items: _relations.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(_titleCase(r)),
                          )).toList(),
                      onChanged: (v) => setState(() => _relation = v),
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

  Widget _readOnlyIdentitySection(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (ctx, auth) {
        final u = auth.user;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.mail_outline, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(u?.email ?? '—', style: theme.textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(u?.mobile ?? '—', style: theme.textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/profile/security'),
                  child: const Text('Change email or mobile'),
                ),
              ),
            ],
          ),
        );
      },
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
