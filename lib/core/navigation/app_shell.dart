import 'dart:async';
import 'package:beltech/core/di/update_providers.dart';
import 'package:beltech/core/di/sync_providers.dart';
import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/navigation/app_shell_helpers.dart';
import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:beltech/core/navigation/widgets/biometric_lock_overlay.dart';
import 'package:beltech/core/navigation/widgets/shell_body_switcher.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:beltech/core/update/presentation/app_update_dialog.dart';
import 'package:beltech/core/widgets/app_dialog.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/analytics/presentation/analytics_screen.dart';
import 'package:beltech/features/assistant/presentation/assistant_screen.dart';
import 'package:beltech/features/calendar/presentation/calendar_screen.dart';
import 'package:beltech/features/expenses/presentation/expenses_screen.dart';
import 'package:beltech/features/home/presentation/home_screen.dart';
import 'package:beltech/features/profile/presentation/profile_screen.dart';
import 'package:beltech/features/tasks/presentation/tasks_screen.dart';
import 'package:beltech/core/sync/background_sync_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    AnalyticsScreen(),
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
  late final BackgroundSyncCoordinator _backgroundSyncCoordinator;
  bool _updateChecked = false;
  bool _biometricConfigured = false;
  bool _appLocked = false;
  bool _biometricUnlockInProgress = false;
  String? _biometricLockMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundSyncCoordinator = ref.read(backgroundSyncCoordinatorProvider);
    unawaited(_startBackgroundSync());
    unawaited(_initializeBiometricLock());
    unawaited(cleanupNotificationReminders(ref));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForAppUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundSyncCoordinator.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNow());
      unawaited(_materializeRecurringNow());
      unawaited(_runNotificationSweep());
      unawaited(cleanupNotificationReminders(ref));
      unawaited(_applyBiometricLockOnResume());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabIndexProvider);
    final accent = accentForTab(currentIndex);
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
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.shellHorizontal,
                  0,
                  AppSpacing.shellHorizontal,
                  AppSpacing.navBottom(context),
                ),
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
                          icon: Icon(Icons.query_stats_outlined),
                          selectedIcon: Icon(Icons.query_stats),
                          label: 'Analytics',
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
            BiometricLockOverlay(
              busy: _biometricUnlockInProgress,
              message: _biometricLockMessage,
              onUnlock: _unlockWithBiometrics,
            ),
        ],
      ),
    );
  }

  Future<void> _startBackgroundSync() async {
    await _backgroundSyncCoordinator.start();
  }

  Future<void> _materializeRecurringNow() async {
    await _backgroundSyncCoordinator.materializeNow();
  }

  Future<void> _syncNow() async {
    await _backgroundSyncCoordinator.syncNow();
  }

  Future<void> _runNotificationSweep() async {
    await _backgroundSyncCoordinator.runNotificationSweep();
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
