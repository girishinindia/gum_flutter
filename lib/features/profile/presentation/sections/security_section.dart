// Security section.
//
// Entry list with three actions. Each pushes to a dedicated flow
// screen. After any of the three flows succeeds, the server
// invalidates the session and we wipe locally + redirect to /login.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../auth/bloc/auth_state.dart';
import 'change_contact_screen.dart';
import 'change_password_screen.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final u = state.user;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (u != null) Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sign-in identifiers',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Email: ${u.email}', style: theme.textTheme.bodySmall),
                              Text('Mobile: ${u.mobile}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _SecurityTile(
                  icon: Icons.password,
                  title: 'Change password',
                  subtitle: 'Verify your identity on both email and mobile, then set a new password.',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  )),
                ),
                _SecurityTile(
                  icon: Icons.mail_outline,
                  title: 'Change email',
                  subtitle: "We'll send a 6-digit code to the new address to confirm.",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChangeContactScreen(kind: ContactKind.email),
                  )),
                ),
                _SecurityTile(
                  icon: Icons.phone_outlined,
                  title: 'Change mobile',
                  subtitle: "We'll send a 6-digit code to the new number to confirm.",
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChangeContactScreen(kind: ContactKind.mobile),
                  )),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: Icon(Icons.logout, color: theme.colorScheme.error),
                  title: Text('Sign out of this device',
                      style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text('You can sign back in any time.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Cancel')),
                          FilledButton.tonal(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Sign out')),
                        ],
                      ),
                    );
                    if (!context.mounted || confirm != true) return;
                    context.read<AuthBloc>().add(const AuthLoggedOut());
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

