// KYC + Bank section.
//
// Two halves under one form:
//   • Identity — PAN (auto-uppercased + format check), Aadhaar (12
//     digits, masked), passport.
//   • Bank + UPI — account holder name, bank name, account number,
//     IFSC (auto-uppercased), UPI handle.
//
// Saves via PUT /user-profiles/me. Validators are routed through the
// FormValidators library so the same rules hold as on web. Sensitive
// fields (PAN / Aadhaar / account number) use `obscureText` until
// the user taps the eye icon.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../domain/user_profile.dart';

class KycBankSection extends StatefulWidget {
  const KycBankSection({super.key});

  @override
  State<KycBankSection> createState() => _KycBankSectionState();
}

class _KycBankSectionState extends State<KycBankSection> {
  final _formKey  = GlobalKey<FormState>();

  final _panCtl     = TextEditingController();
  final _aadhaarCtl = TextEditingController();
  final _passportCtl = TextEditingController();

  final _holderCtl  = TextEditingController();
  final _bankCtl    = TextEditingController();
  final _acctCtl    = TextEditingController();
  final _ifscCtl    = TextEditingController();
  final _upiCtl     = TextEditingController();

  bool _showPan      = false;
  bool _showAadhaar  = false;
  bool _showAccount  = false;

  bool _hydrated   = false;
  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _panCtl.dispose();
    _aadhaarCtl.dispose();
    _passportCtl.dispose();
    _holderCtl.dispose();
    _bankCtl.dispose();
    _acctCtl.dispose();
    _ifscCtl.dispose();
    _upiCtl.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    if (_hydrated) return;
    _panCtl.text      = p.panNumber ?? '';
    _aadhaarCtl.text  = p.aadharNumber ?? '';
    _passportCtl.text = p.passportNumber ?? '';
    _holderCtl.text   = p.bankAccountName ?? '';
    _bankCtl.text     = p.bankName ?? '';
    _acctCtl.text     = p.bankAccountNumber ?? '';
    _ifscCtl.text     = p.bankIfscCode ?? '';
    _upiCtl.text      = p.upiId ?? '';
    _hydrated = true;
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);

    String? nilOrTrim(String s) {
      final t = s.trim();
      return t.isEmpty ? null : t;
    }

    try {
      final patch = <String, dynamic>{
        'pan_number':           nilOrTrim(_panCtl.text)?.toUpperCase(),
        'aadhar_number':        nilOrTrim(_aadhaarCtl.text)?.replaceAll(RegExp(r'\s'), ''),
        'passport_number':      nilOrTrim(_passportCtl.text)?.toUpperCase(),
        'bank_account_name':    nilOrTrim(_holderCtl.text),
        'bank_name':            nilOrTrim(_bankCtl.text),
        'bank_account_number':  nilOrTrim(_acctCtl.text)?.replaceAll(RegExp(r'\s'), ''),
        'bank_ifsc_code':       nilOrTrim(_ifscCtl.text)?.toUpperCase(),
        'upi_id':               nilOrTrim(_upiCtl.text),
      };
      final updated = await bloc.repository.updateProfile(patch);
      if (!mounted) return;
      bloc.add(ProfileProfileUpdated(updated));
      messenger.showSnackBar(const SnackBar(content: Text('Saved.')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('KYC & Bank')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _hydrate(state.bundle!.profile);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SecurityNotice(),
                    const SizedBox(height: 16),
                    Text('Identity',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _panCtl,
                      obscureText: !_showPan,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        TextInputFormatter.withFunction((_, n) =>
                            TextEditingValue(text: n.text.toUpperCase(), selection: n.selection)),
                      ],
                      decoration: InputDecoration(
                        labelText: 'PAN number',
                        helperText: 'Format: 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F).',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_showPan ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showPan = !_showPan),
                        ),
                      ),
                      validator: (v) => FormValidators.pan(v).msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _aadhaarCtl,
                      obscureText: !_showAadhaar,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Aadhaar number',
                        helperText: 'Exactly 12 digits.',
                        prefixIcon: const Icon(Icons.credit_card_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_showAadhaar ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showAadhaar = !_showAadhaar),
                        ),
                      ),
                      validator: (v) => FormValidators.aadhaar(v).msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passportCtl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(8),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        TextInputFormatter.withFunction((_, n) =>
                            TextEditingValue(text: n.text.toUpperCase(), selection: n.selection)),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Passport number',
                        helperText: '8 characters (e.g. A1234567).',
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                      validator: (v) => FormValidators.passport(v).msg,
                    ),

                    const SizedBox(height: 22),
                    Text('Bank account',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _holderCtl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      decoration: const InputDecoration(
                        labelText: 'Account holder name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => FormValidators.maxLen(v, 120, label: 'Account holder name').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bankCtl,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      decoration: const InputDecoration(
                        labelText: 'Bank name',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      validator: (v) => FormValidators.maxLen(v, 120, label: 'Bank name').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _acctCtl,
                      obscureText: !_showAccount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(18),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Account number',
                        helperText: '9 to 18 digits.',
                        prefixIcon: const Icon(Icons.numbers),
                        suffixIcon: IconButton(
                          icon: Icon(_showAccount ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showAccount = !_showAccount),
                        ),
                      ),
                      validator: (v) => FormValidators.bankAccountNumber(v).msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ifscCtl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(11),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        TextInputFormatter.withFunction((_, n) =>
                            TextEditingValue(text: n.text.toUpperCase(), selection: n.selection)),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'IFSC',
                        helperText: '4 letters + 0 + 6 chars (e.g. SBIN0001234).',
                        prefixIcon: Icon(Icons.qr_code_outlined),
                      ),
                      validator: (v) => FormValidators.ifsc(v).msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _upiCtl,
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                      decoration: const InputDecoration(
                        labelText: 'UPI ID',
                        helperText: 'e.g. anjali@oksbi',
                        prefixIcon: Icon(Icons.qr_code_2),
                      ),
                      validator: (v) => FormValidators.upi(v).msg,
                    ),

                    if (_formError != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _formError!),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _save,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "These fields are private — used for payouts and KYC verification. "
              "Tap the eye icon to reveal sensitive numbers while typing.",
              style: theme.textTheme.bodySmall,
            ),
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
