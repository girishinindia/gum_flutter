// Shared client-side validation for auth + profile forms.
//
// 1:1 port of `gum_web/lib/auth/validation.ts`. Every helper returns a
// `ValidationResult` — `ok` on success, or a user-facing message on
// failure. Rules match the server's Zod schemas so passes here don't
// get rejected later.
//
// All validators are pure functions — no side effects. UI hooks them
// up via TextFormField.validator: `(v) => FormValidators.email(v).msg`.

class ValidationResult {
  const ValidationResult._(this.ok, this.msg);

  factory ValidationResult.ok() => const ValidationResult._(true, null);
  factory ValidationResult.err(String msg) => ValidationResult._(false, msg);

  final bool ok;
  final String? msg;
}

class FormValidators {
  FormValidators._();

  // ── Regex (verbatim from validation.ts) ────────────────────────────
  static final _nameRe     = RegExp(r"^[A-Za-z][A-Za-z\s'-]{0,19}$");
  static final _emailRe    = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _panRe      = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _aadhaarRe  = RegExp(r'^[0-9]{12}$');
  static final _ifscRe     = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$', caseSensitive: false);
  static final _upiRe      = RegExp(r'^[\w.\-]{2,256}@[\w]{2,64}$');
  static final _pinRe      = RegExp(r'^[1-9][0-9]{5}$');
  static final _passportRe = RegExp(r'^[A-PR-WY][1-9]\d{6}[1-9]$', caseSensitive: false);
  static final _urlRe      = RegExp(r'^https?:\/\/[^\s/$.?#][^\s]*$', caseSensitive: false);

  // ── Core auth fields ───────────────────────────────────────────────

  static ValidationResult name(String? value, {String fieldLabel = 'Name'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.err('$fieldLabel is required.');
    if (v.length < 2) return ValidationResult.err('$fieldLabel must be at least 2 characters.');
    if (v.length > 20) return ValidationResult.err('$fieldLabel must be at most 20 characters.');
    if (!_nameRe.hasMatch(v)) return ValidationResult.err('$fieldLabel can only contain letters.');
    return ValidationResult.ok();
  }

  static ValidationResult email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.err('Email is required.');
    if (!_emailRe.hasMatch(v)) return ValidationResult.err('Enter a valid email address.');
    if (v.length > 255) return ValidationResult.err('Email is too long.');
    return ValidationResult.ok();
  }

  /// Indian mobile — exactly 10 digits, must start with 6/7/8/9.
  static ValidationResult mobile(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (v.isEmpty) return ValidationResult.err('Mobile number is required.');
    if (v.length != 10) return ValidationResult.err('Mobile must be exactly 10 digits.');
    if (!RegExp(r'^[6-9]').hasMatch(v)) return ValidationResult.err('Mobile must start with 6, 7, 8, or 9.');
    return ValidationResult.ok();
  }

  static ValidationResult password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return ValidationResult.err('Password is required.');
    if (v.length < 8) return ValidationResult.err('Password must be at least 8 characters.');
    if (v.length > 20) return ValidationResult.err('Password must be at most 20 characters.');
    return ValidationResult.ok();
  }

  // ── Sanitisers used as onChanged transforms ─────────────────────────

  static String sanitizeMobile(String raw, {int maxLen = 10}) {
    final stripped = raw.replaceAll(RegExp(r'\D'), '');
    return stripped.length > maxLen ? stripped.substring(0, maxLen) : stripped;
  }

  static String sanitizeName(String raw, {int maxLen = 20}) {
    final stripped = raw.replaceAll(RegExp(r"[^A-Za-z\s'-]"), '');
    return stripped.length > maxLen ? stripped.substring(0, maxLen) : stripped;
  }

  // ── Combine ────────────────────────────────────────────────────────

  /// Returns the first failing result or [ValidationResult.ok].
  static ValidationResult combine(List<ValidationResult> checks) {
    for (final c in checks) {
      if (!c.ok) return c;
    }
    return ValidationResult.ok();
  }

  // ── Generic helpers ─────────────────────────────────────────────────

  static ValidationResult required(Object? value, {String label = 'This field'}) {
    if (value == null) return ValidationResult.err('$label is required.');
    if (value is num)  return value.isFinite ? ValidationResult.ok() : ValidationResult.err('$label is required.');
    if (value is String) {
      return value.trim().isEmpty ? ValidationResult.err('$label is required.') : ValidationResult.ok();
    }
    return ValidationResult.ok();
  }

  static ValidationResult maxLen(String? value, int max, {String label = 'This field'}) {
    final v = value ?? '';
    if (v.length > max) return ValidationResult.err('$label must be at most $max characters.');
    return ValidationResult.ok();
  }

  static ValidationResult numberRange(
    Object? value, double min, double max, {
    String label = 'Value',
    bool integer = false,
  }) {
    if (value == null) return ValidationResult.ok();
    if (value is String && value.trim().isEmpty) return ValidationResult.ok();
    final num? n = value is num ? value : num.tryParse(value.toString());
    if (n == null || !n.isFinite) return ValidationResult.err('$label must be a number.');
    if (integer && n != n.toInt()) return ValidationResult.err('$label must be a whole number.');
    if (n < min || n > max) return ValidationResult.err('$label must be between $min and $max.');
    return ValidationResult.ok();
  }

  // ── Format validators ──────────────────────────────────────────────

  static ValidationResult url(String? value, {String label = 'URL'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    if (!_urlRe.hasMatch(v)) return ValidationResult.err('$label must start with http:// or https:// (e.g. https://example.com).');
    if (v.length > 1000) return ValidationResult.err('$label is too long.');
    return ValidationResult.ok();
  }

  static ValidationResult pan(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return ValidationResult.ok();
    if (!_panRe.hasMatch(v)) return ValidationResult.err('PAN format: 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F).');
    return ValidationResult.ok();
  }

  static ValidationResult aadhaar(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (v.isEmpty) return ValidationResult.ok();
    if (!_aadhaarRe.hasMatch(v)) return ValidationResult.err('Aadhaar must be exactly 12 digits.');
    return ValidationResult.ok();
  }

  static ValidationResult ifsc(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    if (!_ifscRe.hasMatch(v)) return ValidationResult.err('IFSC format: ABCD0123456 (4 letters + 0 + 6 chars).');
    return ValidationResult.ok();
  }

  static ValidationResult upi(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    if (!_upiRe.hasMatch(v)) return ValidationResult.err('UPI ID format: name@bank (e.g. anjali@oksbi).');
    if (v.length > 100) return ValidationResult.err('UPI ID is too long.');
    return ValidationResult.ok();
  }

  static ValidationResult postalCode(String? value, {String? country}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    final c = (country ?? '').toLowerCase();
    final isIndia = c == 'india' || c.toUpperCase() == 'IN';
    if (isIndia) {
      if (!_pinRe.hasMatch(v)) return ValidationResult.err('PIN code must be 6 digits and cannot start with 0.');
    } else {
      if (v.length > 20) return ValidationResult.err('Postal code is too long.');
    }
    return ValidationResult.ok();
  }

  static ValidationResult passport(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return ValidationResult.ok();
    if (!_passportRe.hasMatch(v)) return ValidationResult.err('Passport must be 8 characters (e.g. A1234567).');
    return ValidationResult.ok();
  }

  static ValidationResult bankAccountNumber(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (v.isEmpty) return ValidationResult.ok();
    if (!RegExp(r'^[0-9]{9,18}$').hasMatch(v)) return ValidationResult.err('Account number must be 9 to 18 digits.');
    return ValidationResult.ok();
  }

  // ── Date validators ────────────────────────────────────────────────

  static ValidationResult date(
    String? value, {
    String label = 'Date',
    bool notFuture = false,
    bool notPast = false,
    String? min,
    String? max,
  }) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    final parsed = DateTime.tryParse(v);
    if (parsed == null) return ValidationResult.err('$label is not a valid date.');
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (notFuture && parsed.isAfter(endOfToday)) {
      return ValidationResult.err('$label cannot be in the future.');
    }
    if (notPast && parsed.isBefore(startOfToday)) {
      return ValidationResult.err('$label cannot be in the past.');
    }
    if (min != null) {
      final minD = DateTime.tryParse(min);
      if (minD != null && parsed.isBefore(minD)) return ValidationResult.err('$label must be on or after $min.');
    }
    if (max != null) {
      final maxD = DateTime.tryParse(max);
      if (maxD != null && parsed.isAfter(maxD)) return ValidationResult.err('$label must be on or before $max.');
    }
    return ValidationResult.ok();
  }

  static ValidationResult dateRange(
    String? start,
    String? end, {
    String startLabel = 'Start date',
    String endLabel = 'End date',
  }) {
    final s = (start ?? '').trim();
    final e = (end ?? '').trim();
    if (s.isEmpty || e.isEmpty) return ValidationResult.ok();
    final sd = DateTime.tryParse(s);
    final ed = DateTime.tryParse(e);
    if (sd == null || ed == null) return ValidationResult.ok();
    if (ed.isBefore(sd)) {
      return ValidationResult.err('$endLabel must be on or after ${startLabel.toLowerCase()}.');
    }
    return ValidationResult.ok();
  }

  static ValidationResult age(String? value, {int min = 13, int max = 120}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    final dob = DateTime.tryParse(v);
    if (dob == null) return ValidationResult.err('Date of birth is not a valid date.');
    final today = DateTime.now();
    var age = today.year - dob.year;
    final m = today.month - dob.month;
    if (m < 0 || (m == 0 && today.day < dob.day)) age--;
    if (dob.isAfter(today)) return ValidationResult.err('Date of birth cannot be in the future.');
    if (age < min) return ValidationResult.err('You must be at least $min years old.');
    if (age > max) return ValidationResult.err('Date of birth looks invalid.');
    return ValidationResult.ok();
  }

  // ── File validation ───────────────────────────────────────────────

  /// Validate a file (size in bytes + MIME prefix list). `null` passes
  /// so optional file fields don't trip when empty.
  static ValidationResult file({
    int? sizeBytes,
    String? mimeType,
    int maxMB = 10,
    List<String>? accept,
  }) {
    if (sizeBytes == null) return ValidationResult.ok();
    final maxBytes = maxMB * 1024 * 1024;
    if (sizeBytes > maxBytes) return ValidationResult.err('File must be at most $maxMB MB.');
    if (accept != null && accept.isNotEmpty && mimeType != null) {
      final ok = accept.any((p) => mimeType.startsWith(p));
      if (!ok) return ValidationResult.err('File type not allowed.');
    }
    return ValidationResult.ok();
  }

  // ── Grade helpers (Education) ─────────────────────────────────────

  static ValidationResult grade(String? value, String? gradeType) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    switch (gradeType) {
      case 'percentage':
        final n = num.tryParse(v.replaceAll('%', ''));
        if (n == null || !n.isFinite || n < 0 || n > 100) return ValidationResult.err('Percentage must be between 0 and 100.');
        return ValidationResult.ok();
      case 'cgpa':
      case 'gpa':
        final n = num.tryParse(v);
        if (n == null || !n.isFinite || n < 0 || n > 10) return ValidationResult.err('${gradeType!.toUpperCase()} must be between 0 and 10.');
        return ValidationResult.ok();
      case 'grade':
        if (!RegExp(r'^[A-Fa-f][+\-]?$').hasMatch(v)) return ValidationResult.err('Grade must look like A, B+, C-, etc.');
        return ValidationResult.ok();
      case 'pass_fail':
        if (!RegExp(r'^(pass|fail)$', caseSensitive: false).hasMatch(v)) return ValidationResult.err('Enter "Pass" or "Fail".');
        return ValidationResult.ok();
      default:
        return maxLen(v, 100, label: 'Grade');
    }
  }

  // ── Username / handle ─────────────────────────────────────────────

  static ValidationResult username(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    if (RegExp(r'\s').hasMatch(v)) return ValidationResult.err('Username cannot contain spaces.');
    if (!RegExp(r'^[A-Za-z0-9._\-@]+$').hasMatch(v)) {
      return ValidationResult.err('Username can only contain letters, digits, dots, hyphens, underscores or @.');
    }
    if (v.length > 300) return ValidationResult.err('Username is too long.');
    return ValidationResult.ok();
  }

  // ── Document-number routing ───────────────────────────────────────

  static ValidationResult documentNumber(String? value, String? docName) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationResult.ok();
    final name = (docName ?? '').toLowerCase();
    if (name.contains('pan')) return pan(v);
    if (name.contains('aadhaar') || name.contains('aadhar')) return aadhaar(v);
    if (name.contains('passport')) return passport(v);
    return maxLen(v, 200, label: 'Document number');
  }
}
