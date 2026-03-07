import 'dart:async';

import 'package:dart_2_0/core/di/update_providers.dart';
import 'package:dart_2_0/core/di/sync_providers.dart';
import 'package:dart_2_0/core/navigation/shell_providers.dart';
import 'package:dart_2_0/core/sync/sms_auto_import_service.dart';
import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/theme/glass_styles.dart';
import 'package:dart_2_0/core/update/presentation/app_update_dialog.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/assistant/presentation/assistant_screen.dart';
import 'package:dart_2_0/features/calendar/presentation/calendar_screen.dart';
import 'package:dart_2_0/features/expenses/presentation/expenses_screen.dart';
import 'package:dart_2_0/features/home/presentation/home_screen.dart';
import 'package:dart_2_0/features/profile/presentation/profile_screen.dart';
import 'package:dart_2_0/features/tasks/presentation/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoImportService = ref.read(smsAutoImportServiceProvider);
    unawaited(_startAutoImport());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForAppUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoImportService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(shellTabIndexProvider);
    final accent = _accentForTab(currentIndex);
    final accentSoft = accent.withValues(alpha: 0.2);
    final brightness = Theme.of(context).brightness;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: GlassStyles.backgroundGradientFor(brightness),
      ),
      child: Stack(
        children: [
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 360),
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
          Scaffold(
            backgroundColor: Colors.transparent,
            body:
                IndexedStack(index: currentIndex, children: AppShell._screens),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                borderRadius: 28,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    backgroundColor: Colors.transparent,
                    indicatorColor: accentSoft,
                    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
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
        ],
      ),
    );
  }

  Color _accentForTab(int tab) {
    const palette = [
      Color(0xFF2D7CFF),
      Color(0xFF4B8BFF),
      Color(0xFF1F72F1),
      Color(0xFF3F86FF),
      Color(0xFF2E78FF),
      Color(0xFF5A96FF),
    ];
    return palette[tab % palette.length];
  }

  Future<void> _startAutoImport() async {
    await _autoImportService.start();
  }

  Future<void> _syncNow() async {
    await _autoImportService.syncNow();
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
    await showDialog<void>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) => AppUpdateDialog(
        update: update,
        service: service,
      ),
    );
  }
}
