// Dual-channel OTP verification for /auth/verify-otp.
//
// Both channels (email + mobile) must verify before the server hands
// back tokens. Server state stays single-pending-id across both
// channels; each successful verify returns either:
//
//   { both_verified: false, email_verified: …, mobile_verified: … }  → progress
//   { access_token, refresh_token, user: { … } }                      → complete
//
// The repository's `verifyRegisterOtp` discriminates and persists the
// session on complete, returning the hydrated AuthUser. We dispatch
// `AuthLoggedIn(user)` directly with that value — no storage re-read.
//
// Focus management: TabBarView eagerly builds both panes, so we
// disable `autofocus` on the OTP fields and instead drive focus from
// a TabController listener — the active tab's field always has focus.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_pending_state.dart';
import 'widgets/otp_input_field.dart';
import 'widgets/resend_timer.dart';

class RegisterOtpScreen extends StatefulWidget {
  const RegisterOtpScreen({super.key, required this.pending});

  final RegisterPendingState pending;

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailFocus  = FocusNode();
  final _mobileFocus = FocusNode();

  String _emailOtp  = '';
  String _mobileOtp = '';
  String? _emailError;
  String? _mobileError;
  bool _emailVerified  = false;
  bool _mobileVerified = false;
  bool _submitting     = false;
  /// Feeds the resend timers' `disabledWhile`.
  final _busy = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_handleTabChange);
    // Focus the email pane on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocus.requestFocus();
    });
  }

  void _handleTabChange() {
    if (_tabs.indexIsChanging) return;
    final node = _tabs.index == 0 ? _emailFocus : _mobileFocus;
    final verified = _tabs.index == 0 ? _emailVerified : _mobileVerified;
    if (!verified) node.requestFocus();
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChange);
    _tabs.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _busy.dispose();
    super.dispose();
  }

  Future<void> _verify(String channel) async {
    final otp = channel == 'email' ? _emailOtp : _mobileOtp;
    if (otp.length != 6) return;
    setState(() {
      _submitting = true;
      if (channel == 'email')  _emailError  = null;
      else                     _mobileError = null;
    });
    _busy.value = true;
    // Capture handles before await so we don't reach across an
    // async gap onto the BuildContext.
    final bloc = context.read<AuthBloc>();
    final router = GoRouter.of(context);
    try {
      final hydrated = await bloc.repository.verifyRegisterOtp(
            pendingId:        widget.pending.pendingId,
            channel:          channel,
            otp:              otp,
            assignRoleAfter:  widget.pending.role,
          );
      if (!mounted) return;

      if (hydrated != null) {
        // Both channels verified, session persisted by the repo.
        bloc.add(AuthLoggedIn(hydrated));
        // Router's redirect listener will swap to /home on the bloc
        // state change. Call go() explicitly as a safety net in case
        // we end up on the OTP route after a refresh.
        router.go('/home');
        return;
      }

      // Partial — flip this channel to verified and switch tabs to
      // the other one if not yet done.
      setState(() {
        if (channel == 'email')  _emailVerified  = true;
        else                     _mobileVerified = true;
      });
      if (channel == 'email' && !_mobileVerified) {
        _tabs.animateTo(1);
      } else if (channel == 'mobile' && !_emailVerified) {
        _tabs.animateTo(0);
      }
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        if (channel == 'email')  _emailError  = e.message;
        else                     _mobileError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (channel == 'email')  _emailError  = 'Something went wrong. Try again.';
        else                     _mobileError = 'Something went wrong. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
        _busy.value = false;
      }
    }
  }

  Future<int> _resend(String channel) async {
    final bloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    try {
      final next = await bloc.repository.resendRegisterOtp(
            pendingId: widget.pending.pendingId,
            channel:   channel,
          );
      if (!mounted) return next;
      messenger.showSnackBar(SnackBar(content: Text('OTP resent to your $channel.')));
      return next;
    } on ApiError catch (e) {
      if (!mounted) return widget.pending.resendCooldownSeconds;
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: theme.colorScheme.error,
      ));
      return widget.pending.resendCooldownSeconds;
    } catch (_) {
      return widget.pending.resendCooldownSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status && b.status == AuthStatus.authenticated,
      listener: (ctx, _) {
        // Router redirect will move us to /home — safety net.
        ctx.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verify your account'),
          bottom: TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: 'Email${_emailVerified ? "  ✓" : ""}'),
              Tab(text: 'Mobile${_mobileVerified ? "  ✓" : ""}'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _ChannelPane(
              channel: 'email',
              maskedTarget: widget.pending.maskedEmail,
              otpError: _emailError,
              verified: _emailVerified,
              submitting: _submitting,
              initialCooldown: widget.pending.resendCooldownSeconds,
              busyListenable: _busy,
              focusNode: _emailFocus,
              onOtpChanged: (v) => setState(() => _emailOtp = v),
              onSubmit: () => _verify('email'),
              onResend: () => _resend('email'),
            ),
            _ChannelPane(
              channel: 'mobile',
              maskedTarget: widget.pending.maskedMobile,
              otpError: _mobileError,
              verified: _mobileVerified,
              submitting: _submitting,
              initialCooldown: widget.pending.resendCooldownSeconds,
              busyListenable: _busy,
              focusNode: _mobileFocus,
              onOtpChanged: (v) => setState(() => _mobileOtp = v),
              onSubmit: () => _verify('mobile'),
              onResend: () => _resend('mobile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelPane extends StatelessWidget {
  const _ChannelPane({
    required this.channel,
    required this.maskedTarget,
    required this.otpError,
    required this.verified,
    required this.submitting,
    required this.initialCooldown,
    required this.busyListenable,
    required this.focusNode,
    required this.onOtpChanged,
    required this.onSubmit,
    required this.onResend,
  });

  final String  channel;
  final String  maskedTarget;
  final String? otpError;
  final bool    verified;
  final bool    submitting;
  final int     initialCooldown;
  final ValueListenable<bool> busyListenable;
  final FocusNode focusNode;
  final ValueChanged<String> onOtpChanged;
  final VoidCallback onSubmit;
  final Future<int> Function() onResend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              channel == 'email' ? Icons.mail_outline : Icons.sms_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              verified ? 'Verified' : 'Enter the 6-digit code',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              verified
                  ? 'This $channel is verified.'
                  : 'Sent to $maskedTarget',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (!verified) ...[
              OtpInputField(
                length: 6,
                autofocus: false, // focus driven externally
                focusNode: focusNode,
                onChanged: onOtpChanged,
                onCompleted: (_) => onSubmit(),
                error: otpError,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting ? null : onSubmit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: submitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Verify'),
              ),
              const SizedBox(height: 8),
              ResendTimer(
                initialSeconds: initialCooldown,
                onResend: onResend,
                disabledWhile: busyListenable,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
