// Change email / change mobile — one screen, parameterised by kind.
//
// Two-step flow:
//   1. enterValue → user types the new email or mobile, submit calls
//      updateEmailInitiate / updateMobileInitiate. Server sends a
//      single OTP to the NEW value.
//   2. verifyOtp → 6-digit code → updateEmailVerifyOtp /
//      updateMobileVerifyOtp. On success the server returns
//      `{ logged_out: true, new_email/new_mobile }`; we wipe locally
//      and bounce to /login.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/presentation/widgets/otp_input_field.dart';
import '../../../auth/presentation/widgets/resend_timer.dart';

enum ContactKind { email, mobile }

extension on ContactKind {
  String get title => switch (this) {
        ContactKind.email  => 'Change email',
        ContactKind.mobile => 'Change mobile',
      };
  String get newLabel => switch (this) {
        ContactKind.email  => 'New email',
        ContactKind.mobile => 'New mobile (10 digits)',
      };
  IconData get icon => switch (this) {
        ContactKind.email  => Icons.mail_outline,
        ContactKind.mobile => Icons.phone_outlined,
      };
  String get verbalUnit => switch (this) {
        ContactKind.email  => 'email',
        ContactKind.mobile => 'mobile',
      };
}

enum _Step { enterValue, verifyOtp }

class ChangeContactScreen extends StatefulWidget {
  const ChangeContactScreen({super.key, required this.kind});

  final ContactKind kind;

  @override
  State<ChangeContactScreen> createState() => _ChangeContactScreenState();
}

class _ChangeContactScreenState extends State<ChangeContactScreen> {
  _Step _step = _Step.enterValue;

  final _formKey  = GlobalKey<FormState>();
  final _valueCtl = TextEditingController();

  String? _pendingId;
  String? _maskedTarget;
  int     _otpCooldown = 60;
  String  _otpInput    = '';
  String? _otpError;
  final _busy = ValueNotifier<bool>(false);

  bool    _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _valueCtl.dispose();
    _busy.dispose();
    super.dispose();
  }

  Future<void> _initiate() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final bloc = context.read<AuthBloc>();
    try {
      final value = _valueCtl.text.trim();
      final res = widget.kind == ContactKind.email
          ? await bloc.repository.updateEmailInitiate(newEmail: value.toLowerCase())
          : await bloc.repository.updateMobileInitiate(newMobile: value);
      if (!mounted) return;
      setState(() {
        _pendingId    = res['pending_id'] as String?;
        _maskedTarget = (widget.kind == ContactKind.email
                ? (res['new_email']  ?? value)
                : (res['new_mobile'] ?? value)) as String;
        _otpCooldown  = (res['resend_cooldown_seconds'] as num?)?.toInt() ?? 60;
        _step         = _Step.verifyOtp;
        _otpInput     = '';
        _otpError     = null;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_pendingId == null || _otpInput.length != 6) return;
    setState(() {
      _submitting = true;
      _otpError   = null;
    });
    _busy.value = true;
    final bloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = widget.kind == ContactKind.email
          ? await bloc.repository.updateEmailVerifyOtp(
              pendingId: _pendingId!, otp: _otpInput)
          : await bloc.repository.updateMobileVerifyOtp(
              pendingId: _pendingId!, otp: _otpInput);
      if (!mounted) return;
      final loggedOut = (res['logged_out'] ?? false) as bool;
      if (loggedOut) {
        // Server already invalidated the session — wipe locally and
        // dispatch `expired: true` so the bloc skips the redundant
        // server logout call. Then explicitly route to /login so the
        // user isn't stranded on the change screen if the redirect
        // listener misses the bloc emission.
        await bloc.repository.wipeSessionLocally();
        if (!mounted) return;
        bloc.add(const AuthLoggedOut(expired: true));
        messenger.showSnackBar(SnackBar(
          content: Text('Your ${widget.kind.verbalUnit} was updated. Please sign in again.'),
        ));
        GoRouter.of(context).go('/login');
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text('Your ${widget.kind.verbalUnit} was updated.'),
        ));
        Navigator.of(context).maybePop();
      }
    } on ApiError catch (e) {
      if (mounted) setState(() => _otpError = e.message);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _busy.value = false;
      }
    }
  }

  Future<int> _resendOtp() async {
    if (_pendingId == null) return _otpCooldown;
    final bloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final next = widget.kind == ContactKind.email
          ? await bloc.repository.updateEmailResendOtp(pendingId: _pendingId!)
          : await bloc.repository.updateMobileResendOtp(pendingId: _pendingId!);
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('OTP resent.')));
      return next;
    } on ApiError catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return _otpCooldown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      appBar: AppBar(
        title: Text(widget.kind.title),
        leading: _step == _Step.enterValue
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
            _Step.enterValue => _stepEnter(),
            _Step.verifyOtp  => _stepVerify(),
          },
        ),
      ),
    );
  }

  Widget _stepEnter() {
    final theme = Theme.of(context);
    final isEmail = widget.kind == ContactKind.email;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(widget.kind.icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            isEmail ? "What's your new email?" : "What's your new mobile?",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "We'll send a 6-digit code to confirm.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isEmail)
            TextFormField(
              controller: _valueCtl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: widget.kind.newLabel,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: (v) => FormValidators.email(v).msg,
            )
          else
            TextFormField(
              controller: _valueCtl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: widget.kind.newLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
                prefixText: '+91 ',
              ),
              validator: (v) => FormValidators.mobile(v).msg,
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
                : const Text('Send code'),
          ),
        ],
      ),
    );
  }

  Widget _stepVerify() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(widget.kind.icon, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Sent to your new ${widget.kind.verbalUnit}: ${_maskedTarget ?? ''}',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        OtpInputField(
          length: 6,
          onChanged: (v) => setState(() => _otpInput = v),
          onCompleted: (_) => _verifyOtp(),
          error: _otpError,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submitting ? null : _verifyOtp,
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
          initialSeconds: _otpCooldown,
          onResend: _resendOtp,
          disabledWhile: _busy,
        ),
      ],
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
