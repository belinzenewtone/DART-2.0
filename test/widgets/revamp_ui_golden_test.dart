import 'package:beltech/core/di/notification_providers.dart';
import 'package:beltech/core/security/session_lock_settings_repository.dart';
import 'package:beltech/core/theme/app_theme.dart';
import 'package:beltech/features/auth/domain/entities/auth_state.dart';
import 'package:beltech/features/auth/presentation/providers/auth_providers.dart';
import 'package:beltech/features/home/presentation/widgets/home_week_review_ritual_card.dart';
import 'package:beltech/features/review/domain/entities/week_review_data.dart';
import 'package:beltech/features/review/domain/entities/week_review_ritual.dart';
import 'package:beltech/features/review/presentation/providers/review_ritual_providers.dart';
import 'package:beltech/features/settings/presentation/widgets/notification_preferences_section.dart';
import 'package:beltech/features/settings/presentation/widgets/settings_security_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('weekly ritual card matches revamp baseline', (tester) async {
    tester.view.physicalSize = const Size(440, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const ritual = WeekReviewRitual(
      headline: 'Protect your momentum',
      summary: 'Stay focused on your strongest weekly habit.',
      focusLabel: 'Keep',
      focusDetail: 'Carry your routine into next week.',
      tone: WeekReviewInsightTone.positive,
      ctaLabel: 'Start ritual',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weekReviewRitualProvider
              .overrideWith((ref) => const AsyncData(ritual)),
        ],
        child: _wrap(
          const KeyedSubtree(
            key: Key('weekly-ritual-card'),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: HomeWeekReviewRitualCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('weekly-ritual-card')),
      matchesGoldenFile('../goldens/weekly_ritual_card.png'),
    );
  });

  testWidgets('security and notification controls match baseline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(460, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionLockSettingsProvider.overrideWith(
            (ref) async => const SessionLockSettings(gracePeriodSeconds: 30),
          ),
          notificationsEnabledProvider.overrideWith((ref) async => true),
          budgetAlertsEnabledProvider.overrideWith((ref) async => true),
          dailyDigestEnabledProvider.overrideWith((ref) async => true),
          weeklyReviewNotificationsEnabledProvider.overrideWith(
            (ref) async => true,
          ),
        ],
        child: _wrap(
          const KeyedSubtree(
            key: Key('settings-revamp-controls'),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsSecurityCard(
                    state: AuthState(
                      biometricSupported: true,
                      biometricEnabled: true,
                      isAuthenticating: false,
                    ),
                  ),
                  SizedBox(height: 20),
                  NotificationPreferencesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('settings-revamp-controls')),
      matchesGoldenFile('../goldens/settings_revamp_controls.png'),
    );
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}
