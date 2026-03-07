import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/theme_mode_controller.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/auth/domain/entities/auth_state.dart';
import 'package:dart_2_0/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              authState.when(
                data: (state) => _SecurityCard(state: state),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    const _ErrorCard(label: 'Unable to load security settings'),
              ),
              const SizedBox(height: 16),
              Text('Appearance', style: textTheme.titleMedium),
              const SizedBox(height: 10),
              const _AppearanceCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Authentication successful'
                                : 'Authentication failed'),
                          ),
                        );
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
