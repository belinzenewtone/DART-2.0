import 'package:dart_2_0/core/di/notification_providers.dart';
import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_spacing.dart';
import 'package:dart_2_0/core/theme/theme_mode_controller.dart';
import 'package:dart_2_0/core/widgets/app_feedback.dart';
import 'package:dart_2_0/core/widgets/error_message.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/auth/domain/entities/auth_state.dart';
import 'package:dart_2_0/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, '${next.error}');
      }
    });
    ref.listen<AsyncValue<void>>(notificationPreferenceControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Notification preference updated.');
      } else if (next.hasError) {
        AppFeedback.error(context, 'Unable to update notification settings.');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.sectionPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              authState.when(
                data: (state) => _SecurityCard(state: state),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => ErrorMessage(
                  label: 'Unable to load security settings',
                  onRetry: () => ref.invalidate(authProvider),
                ),
              ),
              const SizedBox(height: 16),
              Text('Appearance', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              const _AppearanceCard(),
              const SizedBox(height: 16),
              Text('Data and Tools', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              const _ToolsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  const _ToolsCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _ToolTile(
            icon: Icons.savings_outlined,
            title: 'Budgets',
            subtitle: 'Set monthly limits per category',
            onTap: () => context.pushNamed('budget'),
          ),
          _ToolTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Income',
            subtitle: 'Track incoming cashflow',
            onTap: () => context.pushNamed('income'),
          ),
          _ToolTile(
            icon: Icons.autorenew,
            title: 'Recurring Items',
            subtitle: 'Automate repeating records',
            onTap: () => context.pushNamed('recurring'),
          ),
          _ToolTile(
            icon: Icons.search,
            title: 'Global Search',
            subtitle: 'Search expenses, tasks, events, and more',
            onTap: () => context.pushNamed('search'),
          ),
          _ToolTile(
            icon: Icons.file_download_outlined,
            title: 'Export CSV',
            subtitle: 'Export your data for backup',
            onTap: () => context.pushNamed('export'),
          ),
          _ToolTile(
            icon: Icons.query_stats,
            title: 'Analytics',
            subtitle: 'View trends and performance metrics',
            onTap: () => context.pushNamed('analytics'),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabledState = ref.watch(notificationsEnabledProvider);
    final notificationWriteState =
        ref.watch(notificationPreferenceControllerProvider);
    final notificationsEnabled = notificationsEnabledState.valueOrNull ?? true;

    return GlassCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Biometric Lock'),
            subtitle: Text(
              state.biometricSupported
                  ? 'Use fingerprint/face to unlock secure actions'
                  : 'Biometrics not supported on this device',
            ),
            value: state.biometricEnabled,
            onChanged: state.biometricSupported
                ? (value) async {
                    await ref
                        .read(authProvider.notifier)
                        .setBiometricEnabled(value);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      final ok = await ref
                          .read(authProvider.notifier)
                          .authenticateNow();
                      if (context.mounted) {
                        if (ok) {
                          AppFeedback.success(
                              context, 'Authentication successful.');
                        } else {
                          AppFeedback.error(context, 'Authentication failed.');
                        }
                      }
                    },
              icon: state.isAuthenticating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: const Text('Authenticate Now'),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications'),
            subtitle: const Text('Enable task and event reminders'),
            value: notificationsEnabled,
            onChanged: notificationsEnabledState.isLoading ||
                    notificationWriteState.isLoading
                ? null
                : (value) async {
                    await ref
                        .read(notificationPreferenceControllerProvider.notifier)
                        .setEnabled(value);
                  },
          ),
        ],
      ),
    );
  }
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(currentThemeModeProvider);
    return GlassCard(
      child: Column(
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.palette_outlined, color: AppColors.accent),
            title: Text('Theme'),
            subtitle: Text('Choose your preferred mode'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Auto'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selected) async {
                await ref
                    .read(themeModeControllerProvider.notifier)
                    .setThemeMode(selected.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
