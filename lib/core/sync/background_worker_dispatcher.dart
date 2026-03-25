import 'dart:ui' as ui;

import 'package:beltech/core/config/supabase_config.dart';
import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
import 'package:beltech/core/telemetry/revamp_telemetry_service.dart';
import 'package:beltech/core/sync/sms_auto_import_service.dart';
import 'package:beltech/core/sync/sync_circuit_breaker.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:beltech/features/analytics/data/repositories/supabase_analytics_repository_impl.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:beltech/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:beltech/features/auth/data/repositories/supabase_account_repository_impl.dart';
import 'package:beltech/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:beltech/features/budget/data/repositories/supabase_budget_repository_impl.dart';
import 'package:beltech/features/budget/domain/repositories/budget_repository.dart';
import 'package:beltech/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:beltech/features/calendar/data/repositories/supabase_calendar_repository_impl.dart';
import 'package:beltech/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:beltech/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/repositories/supabase_expenses_repository_impl.dart';
import 'package:beltech/features/expenses/data/services/device_sms_data_source.dart';
import 'package:beltech/features/expenses/data/services/merchant_learning_service.dart';
import 'package:beltech/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:beltech/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:beltech/features/income/data/repositories/income_repository_impl.dart';
import 'package:beltech/features/income/data/repositories/supabase_income_repository_impl.dart';
import 'package:beltech/features/income/domain/repositories/income_repository.dart';
import 'package:beltech/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:beltech/features/recurring/data/repositories/supabase_recurring_repository_impl.dart';
import 'package:beltech/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:beltech/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_data_use_case.dart';
import 'package:beltech/features/review/domain/usecases/build_week_review_ritual_use_case.dart';
import 'package:beltech/features/tasks/data/repositories/supabase_tasks_repository_impl.dart';
import 'package:beltech/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:beltech/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

const String kBackgroundSyncTaskName = 'beltech.background.sync';
const String kBackgroundSyncPeriodicUniqueName = 'com.beltech.app.sync';
const String kBackgroundSyncOneOffUniqueName = 'beltech.background.oneoff';

@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    ui.DartPluginRegistrant.ensureInitialized();
    await BackgroundWorkerRuntime.run();
    return true;
  });
}

class BackgroundWorkerRuntime {
  static Future<void> run() async {
    final useSupabase = await _ensureSupabaseIfConfigured();
    AppDriftStore? localStore;
    try {
      final accountRepository = useSupabase
          ? SupabaseAccountRepositoryImpl(Supabase.instance.client)
          : LocalAccountRepositoryImpl();

      final repositories = _buildRepositories(useSupabase);
      localStore = repositories.localStore;

      final smsService = SmsAutoImportService(
        repositories.expenses,
        accountRepository,
      );
      final recurringService = RecurringMaterializerService(
        repositories.recurring,
      );
      final notifications = LocalNotificationService();
      final flagStore = FeatureFlagStore();
      final insights = NotificationInsightsService(
        notifications,
        repositories.budget,
        repositories.expenses,
        repositories.income,
        repositories.tasks,
        repositories.calendar,
        repositories.analytics,
        accountRepository,
        const BuildWeekReviewDataUseCase(),
        const BuildWeekReviewRitualUseCase(),
        RevampTelemetryService(),
        flagStore,
      );

      if (await flagStore.isEnabled(FeatureFlag.backgroundSync)) {
        final circuit = SyncCircuitBreaker();
        if (await circuit.isOpen()) {
          return; // circuit tripped — skip this run
        }
        try {
          await smsService.syncNow();
          await recurringService.syncNow();
          await circuit.recordSuccess();
        } catch (e) {
          await circuit.recordFailure();
          rethrow;
        }
      }
      if (await flagStore.isEnabled(FeatureFlag.smartNotifications)) {
        await insights.runSweep();
      }
    } catch (error) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'background_worker_last_error',
        '${DateTime.now().toIso8601String()} | $error',
      );
    } finally {
      await localStore?.dispose();
    }
  }

  static _WorkerRepositories _buildRepositories(bool useSupabase) {
    final parser = const MpesaParserService();
    final merchantLearning = MerchantLearningService();
    final smsSource = DeviceSmsDataSource();
    if (useSupabase) {
      final client = Supabase.instance.client;
      return _WorkerRepositories(
        expenses: SupabaseExpensesRepositoryImpl(
          client,
          parser,
          merchantLearning,
          smsSource,
        ),
        recurring: SupabaseRecurringRepositoryImpl(client),
        budget: SupabaseBudgetRepositoryImpl(client),
        income: SupabaseIncomeRepositoryImpl(client),
        tasks: SupabaseTasksRepositoryImpl(client),
        calendar: SupabaseCalendarRepositoryImpl(client),
        analytics: SupabaseAnalyticsRepositoryImpl(client),
      );
    }

    final store = AppDriftStore();
    return _WorkerRepositories(
      localStore: store,
      expenses: ExpensesRepositoryImpl(
        store,
        parser,
        merchantLearning,
        smsSource,
      ),
      recurring: RecurringRepositoryImpl(store),
      budget: BudgetRepositoryImpl(store),
      income: IncomeRepositoryImpl(store),
      tasks: TasksRepositoryImpl(store),
      calendar: CalendarRepositoryImpl(store),
      analytics: AnalyticsRepositoryImpl(store),
    );
  }

  static Future<bool> _ensureSupabaseIfConfigured() async {
    if (!SupabaseConfig.isConfigured) {
      return false;
    }
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publicKey,
      );
      return true;
    }
  }
}

class _WorkerRepositories {
  _WorkerRepositories({
    this.localStore,
    required this.expenses,
    required this.recurring,
    required this.budget,
    required this.income,
    required this.tasks,
    required this.calendar,
    required this.analytics,
  });

  final AppDriftStore? localStore;
  final ExpensesRepository expenses;
  final RecurringRepository recurring;
  final BudgetRepository budget;
  final IncomeRepository income;
  final TasksRepository tasks;
  final CalendarRepository calendar;
  final AnalyticsRepository analytics;
}
