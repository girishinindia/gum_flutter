// Final step of the forgot-password flow — set a new password.
//
// Requires `canResetPassword: true` on the ResetPendingState (set by
// the reset-OTP screen once both channels were verified). Guards
// against direct navigation by routing back to /forgot when called
// without a valid pending state.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/validation/form_validators.dart';
import '../../../shared/widgets/branded_scaffold.dart';
import '../bloc/auth_bloc.dart';
import 'reset_pending_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.pending});

  final ResetPendingState pending;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _passCtl    = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _submitting     = false;
  String? _formError;

  @override
  void dispose() {
    _passCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<AuthBloc>().repository.resetPassword(
            resetPendingId: widget.pending.resetPendingId,
            newPassword:    _passCtl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset successfully. Please sign in.'),
      ));
      context.go('/login');
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
    if (!widget.pending.canResetPassword) {
      // Direct nav without OTPs — bounce back.
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/forgot'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BrandedScaffold(
      hero: true,
      title:    'Pick a strong password',
      subtitle: '8–20 characters. Mix letters, numbers and symbols.',
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
                    TextFormField(
                      controller: _passCtl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'New password',
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
                    if (_formError != null) ...[
                      const SizedBox(height: 14),
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
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Reset password'),
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
