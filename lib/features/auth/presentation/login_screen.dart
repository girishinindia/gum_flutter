// Login screen — Phase A's one fully-functional auth screen.
//
// Drives the AuthRepository.login → AuthBloc.add(AuthLoggedIn(user))
// pipeline end-to-end so we can verify the Dio interceptor, secure
// session, and go_router redirect all work together before stacking
// Register + OTP + Forgot (Phase B) on top.
//
// Validation comes from `FormValidators` so the rules match the
// gum_web side (and ultimately the server's Zod schemas).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/validation/form_validators.dart';
import '../../../shared/widgets/branded_scaffold.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _identifierCtl = TextEditingController();
  final _passwordCtl   = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting      = false;
  String? _formError;

  @override
  void dispose() {
    _identifierCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    // Capture before await so we don't reach across an async gap.
    final bloc   = context.read<AuthBloc>();
    final router = GoRouter.of(context);
    try {
      final user = await bloc.repository.login(
        identifier: _identifierCtl.text.trim(),
        password:   _passwordCtl.text,
      );
      if (!mounted) return;
      bloc.add(AuthLoggedIn(user));
      // The router's refreshListenable should pick up the bloc's new
      // state and redirect /login → /home, but we also call go()
      // explicitly so a stale listener (or a missed notify) doesn't
      // leave the user stuck on this screen.
      router.go('/home');
    } on ApiError catch (e) {
      if (!mounted) return;
      if (e.isSilent) return; // Phase 43.5 — silent 401 → AuthBloc redirects
      setState(() => _formError = e.message);
    } catch (e) {
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
      title:    'Welcome back',
      subtitle: 'Sign in to continue your learning journey.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _Card(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Session-expired banner (driven by AuthState.expired)
                    BlocBuilder<AuthBloc, AuthState>(
                      buildWhen: (a, b) => a.expired != b.expired,
                      builder: (_, s) {
                        if (!s.expired) return const SizedBox.shrink();
                        return _Banner(
                          color: theme.colorScheme.errorContainer,
                          textColor: theme.colorScheme.onErrorContainer,
                          icon: Icons.info_outline,
                          message: 'Your session expired. Please sign in again.',
                        );
                      },
                    ),

                    // Identifier (email or mobile)
                    TextFormField(
                      controller:        _identifierCtl,
                      autofillHints:     const [AutofillHints.username, AutofillHints.email],
                      keyboardType:      TextInputType.emailAddress,
                      textInputAction:   TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email or mobile',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Email or mobile is required.';
                        if (s.contains('@')) return FormValidators.email(s).msg;
                        return FormValidators.mobile(s).msg;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller:      _passwordCtl,
                      autofillHints:   const [AutofillHints.password],
                      obscureText:     _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => FormValidators.password(v).msg,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot'),
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    if (_formError != null) ...[
                      const SizedBox(height: 4),
                      _Banner(
                        color:     theme.colorScheme.errorContainer,
                        textColor: theme.colorScheme.onErrorContainer,
                        icon:      Icons.error_outline,
                        message:   _formError!,
                      ),
                    ],

                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Sign in'),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("New here? ", style: theme.textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Create an account',
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

/// Floating white card that hosts the form content under the
/// BrandedScaffold's aurora hero. Keeps the form legible against the
/// gradient and gives auth screens the same elevated-card feel as the
/// home page's offers carousel + featured card.
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

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.message,
  });

  final Color color;
  final Color textColor;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: textColor, fontSize: 13.5))),
        ],
      ),
    );
  }
}
