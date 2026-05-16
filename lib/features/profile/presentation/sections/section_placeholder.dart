// Generic placeholder for profile sections that haven't shipped yet.
// Used by /profile/contact, /address, /education, /experience, …
// until Phases E–G replace the route binding with the real section
// screen. Reads section metadata so the placeholder's title + icon
// match the home-screen tile the user just tapped.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/branded_scaffold.dart';
import '../profile_section_meta.dart';

class ProfileSectionPlaceholder extends StatelessWidget {
  const ProfileSectionPlaceholder({super.key, required this.section, required this.phaseLabel});

  final ProfileSection section;
  /// "Phase E", "Phase F", "Phase G" — surfaced so the user knows
  /// what's queued and where in the rollout it lives.
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandedScaffold(
      appBar: AppBar(title: Text(section.title)),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(section.icon, size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  section.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${section.subtitle}\n\nThis section ships in $phaseLabel — the foundation '
                  '(BLoC + repository + API services) is already in place.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to profile'),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
