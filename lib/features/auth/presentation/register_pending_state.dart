// State object passed via GoRouter.extra between /register and
// /register/verify. Carries everything the OTP screen needs to drive
// the dual-channel verification + post-success role assignment.
//
// Why a class and not a Map: type-safety. The OTP screen would
// otherwise need null-cast every field by hand.

import '../data/auth_api.dart';

class RegisterPendingState {
  const RegisterPendingState({
    required this.pendingId,
    required this.maskedEmail,
    required this.maskedMobile,
    required this.initialOtpExpirySeconds,
    required this.resendCooldownSeconds,
    required this.role,
  });

  final String pendingId;
  /// Server-masked e.g. `g***@gmail.com`.
  final String maskedEmail;
  /// Server-masked e.g. `******1234`.
  final String maskedMobile;
  final int    initialOtpExpirySeconds;
  final int    resendCooldownSeconds;
  /// Role to assign post-verification (POST /users/me/roles).
  final SelfAssignableRole role;
}
