// Badges section — read-only.
//
// Badges are awarded by the backend (course completions, milestones,
// certifications). The mobile app only lists them — there's no
// mutation surface.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_state.dart';
import '../../domain/user_sub_resources.dart';

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (!state.isLoaded || state.bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final badges = state.bundle!.badges;
          if (badges.isEmpty) return _empty(context);
          return SafeArea(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: badges.length,
              itemBuilder: (_, i) => _BadgeCard(entry: badges[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('No badges yet',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              "Complete courses and milestones to earn badges. They'll appear here.",
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.entry});
  final UserBadge entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = (() {
      final dt = DateTime.tryParse(entry.awardedAt);
      return dt == null ? entry.awardedAt : DateFormat('MMM d, yyyy').format(dt);
    })();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.tertiaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: (entry.iconUrl ?? '').isNotEmpty
                    ? Image.network(
                        entry.iconUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.emoji_events,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : Icon(
                        Icons.emoji_events,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.badgeName,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
