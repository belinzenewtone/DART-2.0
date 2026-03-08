import 'dart:async';

import 'package:dart_2_0/core/di/update_providers.dart';
import 'package:dart_2_0/core/di/sync_providers.dart';
import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/core/navigation/shell_providers.dart';
import 'package:dart_2_0/core/navigation/widgets/shell_body_switcher.dart';
import 'package:dart_2_0/core/sync/sms_auto_import_service.dart';
import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/app_motion.dart';
import 'package:dart_2_0/core/theme/glass_styles.dart';
import 'package:dart_2_0/core/update/presentation/app_update_dialog.dart';
import 'package:dart_2_0/core/widgets/app_dialog.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/assistant/presentation/assistant_screen.dart';
import 'package:dart_2_0/features/calendar/presentation/calendar_screen.dart';
import 'package:dart_2_0/features/expenses/presentation/expenses_screen.dart';
import 'package:dart_2_0/features/home/presentation/home_screen.dart';
import 'package:dart_2_0/features/profile/presentation/profile_screen.dart';
import 'package:dart_2_0/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_2_0/features/recurring/data/services/recurring_materializer_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    ExpensesScreen(),
    TasksScreen(),
    AssistantScreen(),
    ProfileScreen(),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  late final SmsAutoImportService _autoImportService;
  late final RecurringMaterializerService _recurringMaterializerService;
  bool _updateChecked = false;
  bool _biometricConfigured = false;
  bool _appLocked = false;
  bool _biometricUnlockInProgress = false;
  String? _biometricLockMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoImportService = ref.read(smsAutoImportServiceProvider);
    _recurringMaterializerService =
        ref.read(recurringMaterializerServiceProvider);
    unawaited(_startAutoImport());
    unawaited(_startRecurringMaterialization());
    unawaited(_initializeBiometricLock());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForAppUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoImportService.stop();
    _recurringMaterializerService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNow());
      unawaited(_materializeRecurringNow());
      unawaited(_applyBiometricLockOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabIndexProvider);
    final accent = _accentForTab(currentIndex);
    final accentSoft = accent.withValues(alpha: 0.2);
    final brightness = Theme.of(context).brightness;
    final reduceMotion = AppMotion.reduceMotion(context);
    final overlayDuration =
        AppMotion.duration(context, normalMs: 240, reducedMs: 0);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: GlassStyles.backgroundGradientFor(brightness),
      ),
      child: Stack(
        children: [
          IgnorePointer(
            child: AnimatedContainer(
              duration: overlayDuration,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.75, -0.9),
                  radius: 1.05,
                  colors: [accent.withValues(alpha: 0.24), Colors.transparent],
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: _appLocked,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: ShellBodySwitcher(
                currentIndex: currentIndex,
                reduceMotion: reduceMotion,
                children: AppShell._screens,
              ),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  borderRadius: 28,
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      indicatorColor: accentSoft,
                      labelTextStyle:
                          WidgetStateProperty.resolveWith<TextStyle?>(
                        (states) => TextStyle(
                          color: states.contains(WidgetState.selected)
                              ? accent
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      backgroundColor: Colors.transparent,
                      selectedIndex: currentIndex,
                      onDestinationSelected: (index) {
                        ref.read(shellTabIndexProvider.notifier).state = index;
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon: Icon(Icons.calendar_month),
                          label: 'Calendar',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.receipt_long_outlined),
                          selectedIcon: Icon(Icons.receipt_long),
                          label: 'Expenses',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.check_circle_outline),
                          selectedIcon: Icon(Icons.check_circle),
                          label: 'Tasks',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.smart_toy_outlined),
                          selectedIcon: Icon(Icons.smart_toy),
                          label: 'AI',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_appLocked)
            _BiometricLockOverlay(
              busy: _biometricUnlockInProgress,
              message: _biometricLockMessage,
              onUnlock: _unlockWithBiometrics,
            ),
        ],
      ),
    );
  }

  Color _accentForTab(int tab) {
    const palette = [
      Color(0xFF2D7CFF),
      Color(0xFF2AAE9D),
      Color(0xFF3A8AE8),
      Color(0xFFE4895E),
      Color(0xFF6D77E8),
      Color(0xFF3E91D6),
    ];
    return palette[tab % palette.length];
  }

  Future<void> _startAutoImport() async {
    await _autoImportService.start();
  }

  Future<void> _syncNow() async {
    await _autoImportService.syncNow();
  }

  Future<void> _startRecurringMaterialization() async {
    await _recurringMaterializerService.start();
  }

  Future<void> _materializeRecurringNow() async {
    await _recurringMaterializerService.syncNow();
  }

  Future<void> _checkForAppUpdate() async {
    if (_updateChecked || !mounted) {
      return;
    }
    _updateChecked = true;
    final service = ref.read(appUpdateServiceProvider);
    final update = await service.fetchAvailableUpdate();
    if (update == null || !mounted) {
      return;
    }
    await showAppDialog<void>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) => AppUpdateDialog(
        update: update,
        service: service,
      ),
    );
  }

  Future<void> _initializeBiometricLock() async {
    await _refreshBiometricConfiguration(lockNow: true);
    if (_biometricConfigured) {
      await _unlockWithBiometrics();
    }
  }

  Future<void> _applyBiometricLockOnResume() async {
    await _refreshBiometricConfiguration(lockNow: true);
    if (_biometricConfigured) {
      await _unlockWithBiometrics();
    }
  }

  Future<void> _refreshBiometricConfiguration({required bool lockNow}) async {
    final authRepository = ref.read(authRepositoryProvider);
    final enabled = await authRepository.isBiometricEnabled();
    final supported = await authRepository.isBiometricSupported();
    final configured = enabled && supported;
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricConfigured = configured;
      if (!configured) {
        _appLocked = false;
        _biometricLockMessage = null;
        return;
      }
      if (lockNow) {
        _appLocked = true;
      }
    });
  }

  Future<void> _unlockWithBiometrics() async {
    if (_biometricUnlockInProgress || !_biometricConfigured) {
      return;
    }
    setState(() {
      _biometricUnlockInProgress = true;
      _biometricLockMessage = null;
    });

    final authenticated = await ref.read(authRepositoryProvider).authenticate();
    if (!mounted) {
      return;
    }

    setState(() {
      _biometricUnlockInProgress = false;
      _appLocked = !authenticated;
      _biometricLockMessage =
          authenticated ? null : 'Authentication was not completed.';
    });
  }
}

class _BiometricLockOverlay extends StatelessWidget {
  const _BiometricLockOverlay({
    required this.busy,
    required this.message,
    required this.onUnlock,
  });

  final bool busy;
  final String? message;
  final Future<void> Function() onUnlock;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.background.withValues(alpha: 0.8),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      color: AppColors.accent,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock BELTECH',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use your fingerprint or face to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy ? null : () => onUnlock(),
                        icon: busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open_rounded),
                        label: Text(busy ? 'Authenticating...' : 'Unlock'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
