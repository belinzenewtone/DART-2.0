import 'dart:ui' as ui;

import 'package:beltech/core/config/supabase_config.dart';
import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/notifications/local_notification_service.dart';
import 'package:beltech/core/notifications/notification_insights_service.dart';
import 'package:beltech/core/sync/bill_reminder_service.dart';
import 'package:beltech/core/sync/learning_reminder_service.dart';
import 'package:beltech/core/sync/cloud_mirror_service.dart';
import 'package:beltech/core/sync/cloud_sync_dispatcher.dart';
import 'package:beltech/core/sync/sync_mutation_enqueuer.dart';
import 'package:beltech/core/telemetry/revamp_telemetry_service.dart';
import 'package:beltech/core/sync/sms_auto_import_service.dart';
import 'package:beltech/core/sync/sync_circuit_breaker.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/sync_job_store.dart';
import 'package:beltech/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:beltech/features/analytics/data/repositories/supabase_analytics_repository_impl.dart';
import 'package:beltech/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:beltech/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:beltech/features/auth/data/repositories/supabase_account_repository_impl.dart';
import 'package:beltech/features/bills/data/repositories/bills_repository_impl.dart';
import 'package:beltech/features/bills/domain/entities/bill_item.dart';
import 'package:beltech/features/bills/domain/repositories/bills_repository.dart';
import 'package:beltech/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:beltech/features/budget/data/repositories/supabase_budget_repository_impl.dart';
import 'package:beltech/features/budget/domain/repositories/budget_repository.dart';
import 'package:beltech/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:beltech/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:beltech/features/goals/domain/entities/goal_item.dart';
import 'package:beltech/features/goals/domain/repositories/goals_repository.dart';
import 'package:beltech/features/learning/data/repositories/learning_repository_impl.dart';
import 'package:beltech/features/learning/domain/entities/learning_session.dart';
import 'package:beltech/features/learning/domain/repositories/learning_repository.dart';
import 'package:beltech/features/loans/data/repositories/loans_repository_impl.dart';
import 'package:beltech/features/loans/domain/entities/loan_item.dart';
import 'package:beltech/features/loans/domain/repositories/loans_repository.dart';
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
      final billReminder = BillReminderService(
        repositories.bills,
        notifications,
      );
      final learningReminder = LearningReminderService(
        repositories.learning,
        notifications,
      );
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
      final rolloutUserId = accountRepository.currentSession().userId;

      if (await flagStore.isEnabledFor(
        FeatureFlag.backgroundSync,
        userId: rolloutUserId,
      )) {
        final circuit = SyncCircuitBreaker();
        if (await circuit.isOpen()) {
          return; // circuit tripped — skip this run
        }
        try {
          await smsService.syncNow();
          await recurringService.syncNow();
          if (localStore != null) {
            await CloudSyncDispatcher(
              SyncJobStore(localStore),
              localStore,
            ).processQueue();
            try {
              final prefs = await SharedPreferences.getInstance();
              final jobStore = SyncJobStore(localStore);
              await CloudMirrorService(
                localStore,
                SyncMutationEnqueuer(jobStore),
                CloudSyncDispatcher(jobStore, localStore),
                prefs,
              ).mirrorSync();
            } catch (_) {
              // mirror failures don't block other sync tasks
            }
          }
          await billReminder.checkAndNotify();
          await learningReminder.checkAndNotify();
          await circuit.recordSuccess();
        } catch (e) {
          await circuit.recordFailure();
          rethrow;
        }
      }
      if (await flagStore.isEnabledFor(
        FeatureFlag.smartNotifications,
        userId: rolloutUserId,
      )) {
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
        bills: _StubBillsRepository(),
        loans: _StubLoansRepository(),
        goals: _StubGoalsRepository(),
        learning: _StubLearningRepository(),
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
      bills: BillsRepositoryImpl(store),
      loans: LoansRepositoryImpl(store),
      goals: GoalsRepositoryImpl(store),
      learning: LearningRepositoryImpl(store),
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
    required this.bills,
    required this.loans,
    required this.goals,
    required this.learning,
  });

  final AppDriftStore? localStore;
  final ExpensesRepository expenses;
  final RecurringRepository recurring;
  final BudgetRepository budget;
  final IncomeRepository income;
  final TasksRepository tasks;
  final CalendarRepository calendar;
  final AnalyticsRepository analytics;
  final BillsRepository bills;
  final LoansRepository loans;
  final GoalsRepository goals;
  final LearningRepository learning;
}

// Minimal stub repositories for background worker when using Supabase
// (real implementations would be added for Supabase if needed)
class _StubBillsRepository implements BillsRepository {
  @override
  Stream<List<BillItem>> watchBills() => Stream.value([]);
  @override
  Future<List<BillItem>> loadBills() => Future.value([]);
  @override
  Future<void> upsertBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    BillUrgency urgency = BillUrgency.medium,
    String? recurrence,
    bool paid = false,
  }) => Future.value();
  @override
  Future<void> updateBill({
    required int id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillUrgency? urgency,
    String? recurrence,
    bool? paid,
  }) => Future.value();
  @override
  Future<void> deleteBill(int id) => Future.value();
  @override
  Future<double> monthlyCommitmentTotal() => Future.value(0);
  @override
  Future<int> overdueCount() => Future.value(0);
}

class _StubLoansRepository implements LoansRepository {
  @override
  Stream<List<LoanItem>> watchLoans() => Stream.value([]);
  @override
  Future<List<LoanItem>> loadLoans() => Future.value([]);
  @override
  Future<void> addLoan({
    required String name,
    String? lender,
    required double totalAmount,
    required double outstandingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus status = LoanStatus.active,
  }) => Future.value();
  @override
  Future<void> updateLoan({
    required int id,
    String? name,
    String? lender,
    double? totalAmount,
    double? outstandingAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? dueDate,
    LoanStatus? status,
  }) => Future.value();
  @override
  Future<void> deleteLoan(int id) => Future.value();
  @override
  Future<double> totalOutstanding() => Future.value(0);
}

class _StubGoalsRepository implements GoalsRepository {
  @override
  Stream<List<GoalItem>> watchGoals() => Stream.value([]);
  @override
  Future<List<GoalItem>> loadGoals() => Future.value([]);
  @override
  Future<void> addGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    String? color,
  }) => Future.value();
  @override
  Future<void> updateGoal({
    required int id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? color,
  }) => Future.value();
  @override
  Future<void> deleteGoal(int id) => Future.value();
}

class _StubLearningRepository implements LearningRepository {
  @override
  Stream<List<LearningSession>> watchSessions() => Stream.value([]);
  @override
  Future<List<LearningSession>> loadSessions() => Future.value([]);
  @override
  Future<void> addSession({
    required String topic,
    required int durationMinutes,
    required DateTime date,
  }) => Future.value();
  @override
  Future<void> deleteSession(int id) => Future.value();
  @override
  Future<int> currentStreak() => Future.value(0);
  @override
  Future<int> monthlyMinutes(DateTime month) => Future.value(0);
}
