// Change password — 4-step flow on a single screen.
//
//   1. enterOld     → old password
//   2. verifyEmail  → email OTP   (verifyOtp(channel:'email'))
//   3. verifyMobile → mobile OTP  (verifyOtp(channel:'mobile'))
//   4. enterNew     → new password (confirm) → server logs out
//
// On success the server invalidates the current session
// (`logged_out: true`). We wipe locally + dispatch `AuthLoggedOut`
// so the router redirects to /login.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/presentation/widgets/otp_input_field.dart';
import '../../../auth/presentation/widgets/resend_timer.dart';

enum _PwStep { enterOld, verifyEmail, verifyMobile, enterNew }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  _PwStep _step = _PwStep.enterOld;

  // Step 1
  final _oldFormKey = GlobalKey<FormState>();
  final _oldCtl     = TextEditingController();
  bool _obscureOld  = true;

  // Step 2 / 3 — OTP
  String? _pendingId;
  String? _maskedEmail;
  String? _maskedMobile;
  int     _otpCooldown = 60;
  String  _otpInput    = '';
  String? _otpError;
  bool    _emailVerified  = false;
  bool    _mobileVerified = false;
  bool    _canSetPassword = false;
  final _busy = ValueNotifier<bool>(false);

  // Step 4
  final _newFormKey = GlobalKey<FormState>();
  final _newCtl     = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _oldCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    _busy.dispose();
    super.dispose();
  }

  Future<void> _initiate() async {
    setState(() => _formError = null);
    if (!_oldFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final bloc = context.read<AuthBloc>();
    try {
      final res = await bloc.repository.changePasswordInitiate(oldPassword: _oldCtl.text);
      if (!mounted) return;
      setState(() {
        _pendingId    = res['pending_id'] as String?;
        _maskedEmail  = (res['email']  ?? '') as String;
        _maskedMobile = (res['mobile'] ?? '') as String;
        _otpCooldown  = (res['resend_cooldown_seconds'] as num?)?.toInt() ?? 60;
        _step         = _PwStep.verifyEmail;
        _otpInput     = '';
        _otpError     = null;
      });
    } on ApiError catch (e) {
      if (e.isSilent) return; // Phase 43.5 — silent 401 → AuthBloc redirects
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtp(String channel) async {
    if (_pendingId == null) return;
    if (_otpInput.length != 6) return;
    setState(() {
      _submitting = true;
      _otpError   = null;
    });
    _busy.value = true;
    final bloc = context.read<AuthBloc>();
    try {
      final res = await bloc.repository.changePasswordVerifyOtp(
        pendingId: _pendingId!,
        channel:   channel,
        otp:       _otpInput,
      );
      if (!mounted) return;
      final emailV  = (res['email_verified']  ?? false) as bool;
      final mobileV = (res['mobile_verified'] ?? false) as bool;
      final canSet  = (res['can_set_password'] ?? false) as bool;
      setState(() {
        _emailVerified  = emailV;
        _mobileVerified = mobileV;
        _canSetPassword = canSet;
        if (canSet) {
          _step = _PwStep.enterNew;
        } else if (channel == 'email') {
          _step     = _PwStep.verifyMobile;
          _otpInput = '';
        } else {
          _step     = _PwStep.verifyEmail;
          _otpInput = '';
        }
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _otpError = e.message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _busy.value = false;
      }
    }
  }

  Future<int> _resendOtp(String channel) async {
    if (_pendingId == null) return _otpCooldown;
    final bloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final next = await bloc.repository.changePasswordResendOtp(
        pendingId: _pendingId!,
        channel:   channel,
      );
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('OTP resent to your $channel.')));
      }
      return next;
    } on ApiError catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return _otpCooldown;
    }
  }

  Future<void> _confirm() async {
    setState(() => _formError = null);
    if (!_newFormKey.currentState!.validate()) return;
    if (_pendingId == null || !_canSetPassword) return;
    setState(() => _submitting = true);
    final bloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final loggedOut = await bloc.repository.changePasswordConfirm(
        pendingId:    _pendingId!,
        newPassword:  _newCtl.text,
      );
      if (!mounted) return;
      if (loggedOut) {
        // Server has already invalidated the session; wipe locally
        // and dispatch with `expired: true` so the AuthBloc skips the
        // server `/auth/logout` round-trip (avoids redundant clear).
        await bloc.repository.wipeSessionLocally();
        if (!mounted) return;
        bloc.add(const AuthLoggedOut(expired: true));
        messenger.showSnackBar(const SnackBar(
          content: Text('Password updated. Please sign in again.'),
        ));
        // Explicit navigation — the refreshListenable redirect has
        // proven unreliable, so we kick the user to /login directly.
        GoRouter.of(context).go('/login');
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Password updated.')));
        Navigator.of(context).maybePop();
      }
    } on ApiError catch (e) {
      if (e.isSilent) return; // Phase 43.5 — silent 401 → AuthBloc redirects
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(
        title: const Text('Change password'),
        leading: _step == _PwStep.enterOld
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
              ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: switch (_step) {
            _PwStep.enterOld     => _stepEnterOld(),
            _PwStep.verifyEmail  => _stepVerifyOtp('email',  _maskedEmail  ?? '—', Icons.mail_outline),
            _PwStep.verifyMobile => _stepVerifyOtp('mobile', _maskedMobile ?? '—', Icons.sms_outlined),
            _PwStep.enterNew     => _stepEnterNew(),
          },
        ),
      ),
    );
  }

  Widget _stepEnterOld() {
    final theme = Theme.of(context);
    return Form(
      key: _oldFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Confirm your current password',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            "We'll then send a 6-digit code to your email and mobile.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _oldCtl,
            obscureText: _obscureOld,
            decoration: InputDecoration(
              labelText: 'Current password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureOld = !_obscureOld),
              ),
            ),
            validator: (v) => FormValidators.password(v).msg,
          ),
          if (_formError != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: _formError!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _initiate,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _stepVerifyOtp(String channel, String masked, IconData icon) {
    final theme = Theme.of(context);
    final progress = [
      if (_emailVerified)  'Email verified',
      if (_mobileVerified) 'Mobile verified',
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('Enter the 6-digit code',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          'Sent to your $channel: $masked',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        if (progress.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(progress,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
        ],
        const SizedBox(height: 28),
        OtpInputField(
          key: ValueKey('otp-$channel'),
          length: 6,
          onChanged: (v) => setState(() => _otpInput = v),
          onCompleted: (_) => _verifyOtp(channel),
          error: _otpError,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submitting ? null : () => _verifyOtp(channel),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _submitting
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('Verify'),
        ),
        const SizedBox(height: 4),
        ResendTimer(
          key: ValueKey('resend-$channel'),
          initialSeconds: _otpCooldown,
          onResend: () => _resendOtp(channel),
          disabledWhile: _busy,
        ),
      ],
    );
  }

  Widget _stepEnterNew() {
    final theme = Theme.of(context);
    return Form(
      key: _newFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.password, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Set a new password',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            '8–20 characters. Mix letters, numbers and symbols.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _newCtl,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) => FormValidators.password(v).msg,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmCtl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Please confirm your password.';
              if (v != _newCtl.text) return "Passwords don't match.";
              return null;
            },
          ),
          if (_formError != null) ...[
            const SizedBox(height: 14),
            _ErrorBanner(message: _formError!),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submitting ? null : _confirm,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : const Text('Update password'),
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
