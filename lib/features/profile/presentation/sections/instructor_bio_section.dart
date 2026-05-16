// Instructor Bio section — instructor-only.
//
// Two halves:
//   • Read-only stats (server-computed) — total students, total
//     courses, average rating, verified / featured flags.
//   • Editable bio — expertise, teaching_languages (free-text
//     comma-separated), years_teaching, paypal_email, stripe_account_id.
//
// The section list hides this entry entirely for non-instructors;
// the screen itself also guards against direct nav by checking
// `AuthBloc.state.user.isInstructor` and bouncing if false.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../shared/widgets/branded_scaffold.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../domain/user_sub_resources.dart';

class InstructorBioSection extends StatefulWidget {
  const InstructorBioSection({super.key});

  @override
  State<InstructorBioSection> createState() => _InstructorBioSectionState();
}

class _InstructorBioSectionState extends State<InstructorBioSection> {
  final _formKey   = GlobalKey<FormState>();
  final _expCtl    = TextEditingController();
  final _langsCtl  = TextEditingController();
  final _yearsCtl  = TextEditingController();
  final _paypalCtl = TextEditingController();
  final _stripeCtl = TextEditingController();

  bool _hydrated   = false;
  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _expCtl.dispose();
    _langsCtl.dispose();
    _yearsCtl.dispose();
    _paypalCtl.dispose();
    _stripeCtl.dispose();
    super.dispose();
  }

  void _hydrate(InstructorProfile? p) {
    if (_hydrated || p == null) return;
    _expCtl.text     = p.expertise ?? '';
    _langsCtl.text   = p.teachingLanguages ?? '';
    _yearsCtl.text   = p.yearsTeaching?.toString() ?? '';
    _paypalCtl.text  = p.paypalEmail ?? '';
    _stripeCtl.text  = p.stripeAccountId ?? '';
    _hydrated = true;
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final years = num.tryParse(_yearsCtl.text.trim());
      final patch = <String, dynamic>{
        if (_expCtl.text.trim().isNotEmpty)    'expertise':          _expCtl.text.trim()
        else                                   'expertise':          null,
        if (_langsCtl.text.trim().isNotEmpty)  'teaching_languages': _langsCtl.text.trim()
        else                                   'teaching_languages': null,
        'years_teaching': years,
        if (_paypalCtl.text.trim().isNotEmpty) 'paypal_email':       _paypalCtl.text.trim()
        else                                   'paypal_email':       null,
        if (_stripeCtl.text.trim().isNotEmpty) 'stripe_account_id':  _stripeCtl.text.trim()
        else                                   'stripe_account_id':  null,
      };
      final updated = await bloc.repository.instructorApi.update(patch);
      if (!mounted) return;
      bloc.add(ProfileInstructorReplaced(updated));
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
    final isInstructor = context.watch<AuthBloc>().state.user?.isInstructor ?? false;
    if (!isInstructor) {
      // Defensive — should never reach here because the section list
      // already hides Instructor Bio for non-instructors.
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/profile'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BrandedScaffold(
      appBar: AppBar(title: const Text('Instructor bio')),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = state.bundle!.instructorProfile;
          _hydrate(p);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsBlock(profile: p),
                    const SizedBox(height: 22),
                    Text(
                      'Editable bio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expCtl,
                      minLines: 2, maxLines: 5,
                      inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                      decoration: const InputDecoration(
                        labelText: 'Areas of expertise',
                        helperText: 'A short paragraph about what you teach.',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => FormValidators.maxLen(v, 2000, label: 'Expertise').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _langsCtl,
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                      decoration: const InputDecoration(
                        labelText: 'Teaching languages',
                        helperText: 'Comma-separated, e.g. "English, Hindi, Gujarati"',
                      ),
                      validator: (v) => FormValidators.maxLen(v, 500, label: 'Teaching languages').msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _yearsCtl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(labelText: 'Years teaching'),
                      validator: (v) => FormValidators.numberRange(v, 0, 80,
                          label: 'Years teaching', integer: true).msg,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _paypalCtl,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [LengthLimitingTextInputFormatter(255)],
                      decoration: const InputDecoration(
                        labelText: 'PayPal email (for payouts)',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        return FormValidators.email(v).msg;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _stripeCtl,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      decoration: const InputDecoration(
                        labelText: 'Stripe account ID',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                      validator: (v) => FormValidators.maxLen(v, 120, label: 'Stripe account ID').msg,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 14),
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

class _StatsBlock extends StatelessWidget {
  const _StatsBlock({required this.profile});
  final InstructorProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final students = profile?.totalStudents ?? 0;
    final courses  = profile?.totalCourses  ?? 0;
    final rating   = profile?.averageRating;
    final verified = profile?.isVerified ?? false;
    final featured = profile?.isFeatured ?? false;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Instructor stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              if (verified)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: _StatusChip(label: 'Verified', icon: Icons.verified, isPositive: true),
                ),
              if (featured)
                const _StatusChip(label: 'Featured', icon: Icons.star, isPositive: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatTile(value: students.toString(), label: 'Students')),
              Expanded(child: _StatTile(value: courses.toString(),  label: 'Courses')),
              Expanded(child: _StatTile(
                value: rating == null ? '—' : rating.toStringAsFixed(1),
                label: 'Avg rating',
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon, required this.isPositive});
  final String label;
  final IconData icon;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
