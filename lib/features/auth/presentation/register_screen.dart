// Registration form — Phase B.
//
// Layout:
//   • First name + Last name (paired row on wide screens)
//   • Email
//   • Mobile (10 digits, +91 prepended server-side)
//   • Password + Confirm password
//   • Role picker (student / instructor)
//   • Terms checkbox
//   • Submit → POST /auth/register → /register/verify
//
// Validation comes from `FormValidators` so the rules match the web
// side and the server's Zod schemas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/validation/form_validators.dart';
import '../../../shared/widgets/branded_scaffold.dart';
import '../bloc/auth_bloc.dart';
import '../data/auth_api.dart';
import 'register_pending_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _firstCtl  = TextEditingController();
  final _lastCtl   = TextEditingController();
  final _emailCtl  = TextEditingController();
  final _mobileCtl = TextEditingController();
  final _passCtl   = TextEditingController();
  final _confirmCtl = TextEditingController();

  SelfAssignableRole _role = SelfAssignableRole.student;
  bool _agreedToTerms = false;
  bool _obscurePass   = true;
  bool _obscureConfirm = true;
  bool _submitting    = false;
  String? _formError;

  @override
  void dispose() {
    _firstCtl.dispose();
    _lastCtl.dispose();
    _emailCtl.dispose();
    _mobileCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(() => _formError = 'Please accept the terms to continue.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final pending = await context.read<AuthBloc>().repository.register(
            firstName: _firstCtl.text.trim(),
            lastName:  _lastCtl.text.trim(),
            email:     _emailCtl.text.trim().toLowerCase(),
            mobile:    _mobileCtl.text.trim(),
            password:  _passCtl.text,
            role:      _role,
          );
      if (!mounted) return;
      context.push('/register/verify', extra: RegisterPendingState(
        pendingId:               pending.pendingId,
        maskedEmail:             pending.email,
        maskedMobile:            pending.mobile,
        initialOtpExpirySeconds: pending.otpExpirySeconds,
        resendCooldownSeconds:   pending.resendCooldownSeconds,
        role:                    _role,
      ));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandedScaffold(
      hero: true,
      title:    'Start your journey',
      subtitle: "We'll send a 6-digit code to your email and mobile to verify both.",
      child: SingleChildScrollView(
        // Halved vertical padding so the form card sits closer to the
        // aurora hero (was 16 → now 8) — matches the gap tightening
        // we applied to the forgot-password screen.
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _Card(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Name pair
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstCtl,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [LengthLimitingTextInputFormatter(20)],
                            onChanged: (v) {
                              final clean = FormValidators.sanitizeName(v);
                              if (clean != v) {
                                _firstCtl.value = TextEditingValue(
                                  text: clean,
                                  selection: TextSelection.collapsed(offset: clean.length),
                                );
                              }
                            },
                            decoration: const InputDecoration(labelText: 'First name'),
                            validator: (v) => FormValidators.name(v, fieldLabel: 'First name').msg,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lastCtl,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [LengthLimitingTextInputFormatter(20)],
                            onChanged: (v) {
                              final clean = FormValidators.sanitizeName(v);
                              if (clean != v) {
                                _lastCtl.value = TextEditingValue(
                                  text: clean,
                                  selection: TextSelection.collapsed(offset: clean.length),
                                );
                              }
                            },
                            decoration: const InputDecoration(labelText: 'Last name'),
                            validator: (v) => FormValidators.name(v, fieldLabel: 'Last name').msg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _emailCtl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) => FormValidators.email(v).msg,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _mobileCtl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Mobile (10 digits)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+91 ',
                      ),
                      validator: (v) => FormValidators.mobile(v).msg,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passCtl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) => FormValidators.password(v).msg,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _confirmCtl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Please confirm your password.';
                        if (v != _passCtl.text) return "Passwords don't match.";
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    // Role picker
                    Text('I want to join as', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    _RolePicker(
                      value: _role,
                      onChanged: (v) => setState(() => _role = v),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'I agree to the Terms of Service and Privacy Policy.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_formError != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
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

                    // 30-pt breathing room between the Terms checkbox
                    // (or error banner) and the primary CTA so the
                    // button doesn't look glued to the form.
                    const SizedBox(height: 30),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Send OTPs'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: theme.textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Sign in',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating white card matching the home page's elevated surfaces.
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final SelfAssignableRole value;
  final ValueChanged<SelfAssignableRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleTile(
            label: 'Student',
            icon:  Icons.school_outlined,
            selected: value == SelfAssignableRole.student,
            onTap:    () => onChanged(SelfAssignableRole.student),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoleTile(
            label: 'Instructor',
            icon:  Icons.workspace_premium_outlined,
            selected: value == SelfAssignableRole.instructor,
            onTap:    () => onChanged(SelfAssignableRole.instructor),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String   label;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
