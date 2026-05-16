// Profile home — summary header + scrollable section list.
//
// Each tile pushes to `/profile/<path>`. Sections marked
// `instructorOnly` are filtered out for non-instructors. Pull-to-
// refresh re-fetches every section in parallel via ProfileBloc.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/branded_scaffold.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'profile_section_meta.dart';

class ProfileHomeScreen extends StatefulWidget {
  const ProfileHomeScreen({super.key});

  @override
  State<ProfileHomeScreen> createState() => _ProfileHomeScreenState();
}

class _ProfileHomeScreenState extends State<ProfileHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the initial load when the screen mounts.
    final bloc = context.read<ProfileBloc>();
    if (bloc.state.status == ProfileStatus.initial) {
      bloc.add(const ProfileLoadRequested());
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<ProfileBloc>();
    bloc.add(const ProfileRefreshRequested());
    // Wait until either loaded or error so the RefreshIndicator
    // animation finishes cleanly.
    await bloc.stream.firstWhere((s) => s.status != ProfileStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrandedScaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        // Explicit back leading — the auto-back arrow inserted by
        // AppBar relies on `ModalRoute.canPop`, which can return
        // `false` inside a go_router ShellRoute (the shell wraps its
        // own nested navigator). Wiring our own IconButton that
        // checks `context.canPop` first, then falls back to
        // `context.go('/home')`, makes the back tap reliable.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Dispatch the bloc event AND explicitly navigate.
              // The router's refreshListenable should bounce us off
              // /profile when state flips to unauthenticated, but
              // we've seen the redirect occasionally miss; the
              // explicit `go('/home')` makes logout deterministic.
              context.read<AuthBloc>().add(const AuthLoggedOut());
              context.go('/home');
            },
          ),
        ],
      ),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.error) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<ProfileBloc>().add(const ProfileLoadRequested(force: true)),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _SummaryHeader(),
                const SizedBox(height: 8),
                if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial)
                  const _SkeletonTiles()
                else
                  ..._sectionTiles(context, theme),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _sectionTiles(BuildContext context, ThemeData theme) {
    final user = context.watch<AuthBloc>().state.user;
    final isInstructor = user?.isInstructor ?? false;
    final visible = profileSections.where((s) => !s.instructorOnly || isInstructor);
    return visible.map((s) => _SectionTile(section: s)).toList(growable: false);
  }
}

class _SummaryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final u = state.user;
        final initials = ((u?.firstName.isNotEmpty == true ? u!.firstName[0] : '') +
                         (u?.lastName.isNotEmpty  == true ? u!.lastName[0]  : ''))
            .toUpperCase();
        final roleLabel = u == null
            ? ''
            : u.isAdmin
                ? 'Admin'
                : u.isInstructor
                    ? 'Instructor'
                    : 'Student';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u == null ? '' : (u.displayName?.trim().isNotEmpty == true
                          ? u.displayName!
                          : u.fullName),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      u?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                      ),
                    ),
                    if (roleLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});
  final ProfileSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Icon(section.icon, size: 22),
      ),
      title: Text(section.title, style: theme.textTheme.titleMedium),
      subtitle: Text(section.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/profile/${section.path}'),
    );
  }
}

class _SkeletonTiles extends StatelessWidget {
  const _SkeletonTiles();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(8, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, color: theme.colorScheme.surfaceContainerHighest),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 220, color: theme.colorScheme.surfaceContainerHighest),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            "Couldn't load profile",
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
