// Response shapes for the dual-channel OTP flow (email + mobile) used
// during registration and password reset.
//
// Mirrors `gum_web/lib/auth/client.ts` types:
//   OtpInitiateResult     — returned by /auth/register, /auth/forgot-password
//   VerifyOtpProgress     — partial verification (one channel done)
//   VerifyOtpComplete     — both channels done → tokens + user
//   ResetInitiateResult   — forgot-password specific (adds reset_pending_id)
//   ResetVerifyProgress   — reset-otp partial (adds can_reset_password)

import 'package:equatable/equatable.dart';

import 'auth_tokens.dart';
import 'auth_user.dart';

class OtpInitiateResult extends Equatable {
  const OtpInitiateResult({
    required this.pendingId,
    required this.email,
    required this.mobile,
    required this.otpExpirySeconds,
    required this.resendCooldownSeconds,
  });

  final String pendingId;
  final String email;   // masked, e.g. "g***@gmail.com"
  final String mobile;  // masked, e.g. "******1234"
  final int    otpExpirySeconds;
  final int    resendCooldownSeconds;

  factory OtpInitiateResult.fromJson(Map<String, dynamic> j) => OtpInitiateResult(
        pendingId:             (j['pending_id']               ?? '') as String,
        email:                 (j['email']                    ?? '') as String,
        mobile:                (j['mobile']                   ?? '') as String,
        otpExpirySeconds:      (j['otp_expiry_seconds']      as num?)?.toInt() ?? 0,
        resendCooldownSeconds: (j['resend_cooldown_seconds'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [pendingId, email, mobile, otpExpirySeconds, resendCooldownSeconds];
}

class VerifyOtpProgress extends Equatable {
  const VerifyOtpProgress({
    required this.bothVerified,
    required this.emailVerified,
    required this.mobileVerified,
  });

  final bool bothVerified;
  final bool emailVerified;
  final bool mobileVerified;

  factory VerifyOtpProgress.fromJson(Map<String, dynamic> j) => VerifyOtpProgress(
        bothVerified:   (j['both_verified']   ?? false) as bool,
        emailVerified:  (j['email_verified']  ?? false) as bool,
        mobileVerified: (j['mobile_verified'] ?? false) as bool,
      );

  @override
  List<Object?> get props => [bothVerified, emailVerified, mobileVerified];
}

class VerifyOtpComplete extends Equatable {
  const VerifyOtpComplete({required this.tokens, required this.user});

  final AuthTokens tokens;
  final AuthUser   user;

  factory VerifyOtpComplete.fromJson(Map<String, dynamic> j) => VerifyOtpComplete(
        tokens: AuthTokens.fromJson(j),
        user:   AuthUser.fromJson((j['user'] as Map<String, dynamic>?) ?? const {}),
      );

  @override
  List<Object?> get props => [tokens, user];
}

/// Discriminator. After /auth/verify-otp succeeds with both channels
/// verified, the server returns the `VerifyOtpComplete` payload. Until
/// then, it returns a `VerifyOtpProgress`. Detect by presence of
/// `access_token`.
bool isOtpComplete(Map<String, dynamic> raw) => raw['access_token'] is String;

class ResetInitiateResult extends Equatable {
  const ResetInitiateResult({
    required this.resetPendingId,
    required this.email,
    required this.mobile,
    required this.otpExpirySeconds,
    required this.resendCooldownSeconds,
  });

  final String resetPendingId;
  final String email;
  final String mobile;
  final int    otpExpirySeconds;
  final int    resendCooldownSeconds;

  factory ResetInitiateResult.fromJson(Map<String, dynamic> j) => ResetInitiateResult(
        resetPendingId:        (j['reset_pending_id']        ?? '') as String,
        email:                 (j['email']                   ?? '') as String,
        mobile:                (j['mobile']                  ?? '') as String,
        otpExpirySeconds:      (j['otp_expiry_seconds']      as num?)?.toInt() ?? 0,
        resendCooldownSeconds: (j['resend_cooldown_seconds'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [resetPendingId, email, mobile, otpExpirySeconds, resendCooldownSeconds];
}

class ResetVerifyProgress extends Equatable {
  const ResetVerifyProgress({
    required this.bothVerified,
    required this.emailVerified,
    required this.mobileVerified,
    required this.canResetPassword,
  });

  final bool bothVerified;
  final bool emailVerified;
  final bool mobileVerified;
  final bool canResetPassword;

  factory ResetVerifyProgress.fromJson(Map<String, dynamic> j) => ResetVerifyProgress(
        bothVerified:     (j['both_verified']       ?? false) as bool,
        emailVerified:    (j['email_verified']      ?? false) as bool,
        mobileVerified:   (j['mobile_verified']     ?? false) as bool,
        canResetPassword: (j['can_reset_password']  ?? false) as bool,
      );

  @override
  List<Object?> get props => [bothVerified, emailVerified, mobileVerified, canResetPassword];
}
