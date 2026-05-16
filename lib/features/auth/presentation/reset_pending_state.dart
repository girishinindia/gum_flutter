// State object passed via GoRouter.extra between the password-reset
// screens (/forgot → /forgot/verify → /forgot/reset).

class ResetPendingState {
  const ResetPendingState({
    required this.resetPendingId,
    required this.maskedEmail,
    required this.maskedMobile,
    required this.initialOtpExpirySeconds,
    required this.resendCooldownSeconds,
    this.canResetPassword = false,
  });

  final String resetPendingId;
  final String maskedEmail;
  final String maskedMobile;
  final int    initialOtpExpirySeconds;
  final int    resendCooldownSeconds;

  /// `true` once both channels have been verified on the reset
  /// pending. The /forgot/reset screen requires this.
  final bool   canResetPassword;

  ResetPendingState copyWith({bool? canResetPassword}) => ResetPendingState(
        resetPendingId:          resetPendingId,
        maskedEmail:             maskedEmail,
        maskedMobile:            maskedMobile,
        initialOtpExpirySeconds: initialOtpExpirySeconds,
        resendCooldownSeconds:   resendCooldownSeconds,
        canResetPassword:        canResetPassword ?? this.canResetPassword,
      );
}
