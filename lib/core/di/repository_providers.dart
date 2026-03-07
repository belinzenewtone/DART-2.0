import 'package:dart_2_0/core/config/assistant_proxy_config.dart';
import 'package:dart_2_0/core/config/supabase_config.dart';
import 'package:dart_2_0/core/di/database_providers.dart';
import 'package:dart_2_0/core/di/security_providers.dart';
import 'package:dart_2_0/core/platform/runtime_env.dart';
import 'package:dart_2_0/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dart_2_0/features/auth/data/repositories/local_account_repository_impl.dart';
import 'package:dart_2_0/features/auth/data/repositories/supabase_account_repository_impl.dart';
import 'package:dart_2_0/features/auth/domain/repositories/account_repository.dart';
import 'package:dart_2_0/features/auth/domain/repositories/auth_repository.dart';
import 'package:dart_2_0/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:dart_2_0/features/assistant/data/repositories/supabase_assistant_repository_impl.dart';
import 'package:dart_2_0/features/assistant/data/services/assistant_proxy_service.dart';
import 'package:dart_2_0/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:dart_2_0/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:dart_2_0/features/budget/data/repositories/supabase_budget_repository_impl.dart';
import 'package:dart_2_0/features/budget/domain/repositories/budget_repository.dart';
import 'package:dart_2_0/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:dart_2_0/features/calendar/data/repositories/supabase_calendar_repository_impl.dart';
import 'package:dart_2_0/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:dart_2_0/features/expenses/data/repositories/expenses_repository_impl.dart';
import 'package:dart_2_0/features/expenses/data/repositories/supabase_expenses_repository_impl.dart';
import 'package:dart_2_0/features/expenses/data/services/device_sms_data_source.dart';
import 'package:dart_2_0/features/expenses/data/services/mpesa_parser_service.dart';
import 'package:dart_2_0/features/expenses/domain/repositories/expenses_repository.dart';
import 'package:dart_2_0/features/export/data/repositories/export_repository_impl.dart';
import 'package:dart_2_0/features/export/data/repositories/supabase_export_repository_impl.dart';
import 'package:dart_2_0/features/export/domain/repositories/export_repository.dart';
import 'package:dart_2_0/features/home/data/repositories/home_repository_impl.dart';
import 'package:dart_2_0/features/home/data/repositories/supabase_home_repository_impl.dart';
import 'package:dart_2_0/features/home/domain/repositories/home_repository.dart';
import 'package:dart_2_0/features/income/data/repositories/income_repository_impl.dart';
import 'package:dart_2_0/features/income/data/repositories/supabase_income_repository_impl.dart';
import 'package:dart_2_0/features/income/domain/repositories/income_repository.dart';
import 'package:dart_2_0/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:dart_2_0/features/profile/data/repositories/supabase_profile_repository_impl.dart';
import 'package:dart_2_0/features/profile/domain/repositories/profile_repository.dart';
import 'package:dart_2_0/features/recurring/data/repositories/recurring_repository_impl.dart';
import 'package:dart_2_0/features/recurring/data/repositories/supabase_recurring_repository_impl.dart';
import 'package:dart_2_0/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:dart_2_0/features/search/data/repositories/global_search_repository_impl.dart';
import 'package:dart_2_0/features/search/data/repositories/supabase_global_search_repository_impl.dart';
import 'package:dart_2_0/features/search/domain/repositories/global_search_repository.dart';
import 'package:dart_2_0/features/tasks/data/repositories/supabase_tasks_repository_impl.dart';
import 'package:dart_2_0/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:dart_2_0/features/tasks/domain/repositories/tasks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final useSupabaseProvider = Provider<bool>(
  (_) => SupabaseConfig.isConfigured && !hasRuntimeEnv('FLUTTER_TEST'),
);

final supabaseClientProvider =
    Provider<SupabaseClient>((_) => Supabase.instance.client);
final deviceSmsDataSourceProvider = Provider<DeviceSmsDataSource>(
  (_) => DeviceSmsDataSource(),
);
final assistantProxyServiceProvider = Provider<AssistantProxyService?>((ref) {
  if (!AssistantProxyConfig.isConfigured) {
    return null;
  }
  return AssistantProxyService(
    endpoint: AssistantProxyConfig.endpoint,
    supabaseClient: ref.watch(useSupabaseProvider)
        ? ref.watch(supabaseClientProvider)
        : null,
  );
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseHomeRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return HomeRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseCalendarRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return CalendarRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseExpensesRepositoryImpl(
      ref.watch(supabaseClientProvider),
      const MpesaParserService(),
      ref.watch(deviceSmsDataSourceProvider),
    );
  }
  return ExpensesRepositoryImpl(
    ref.watch(appDriftStoreProvider),
    const MpesaParserService(),
    ref.watch(deviceSmsDataSourceProvider),
  );
});
final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseIncomeRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return IncomeRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseBudgetRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return BudgetRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseRecurringRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return RecurringRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final globalSearchRepositoryProvider = Provider<GlobalSearchRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseGlobalSearchRepositoryImpl(
        ref.watch(supabaseClientProvider));
  }
  return GlobalSearchRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseExportRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return ExportRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseTasksRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return TasksRepositoryImpl(ref.watch(appDriftStoreProvider));
});
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(localAuthenticationProvider),
    ref.watch(secureCredentialsStoreProvider),
  ),
);
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseAccountRepositoryImpl(ref.watch(supabaseClientProvider));
  }
  return const LocalAccountRepositoryImpl();
});
final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  if (ref.watch(useSupabaseProvider)) {
    return SupabaseAssistantRepositoryImpl(
      ref.watch(supabaseClientProvider),
      proxyService: ref.watch(assistantProxyServiceProvider),
    );
  }
  return AssistantRepositoryImpl(
    ref.watch(assistantProfileStoreProvider),
    ref.watch(appDriftStoreProvider),
    proxyService: ref.watch(assistantProxyServiceProvider),
  );
});
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) {
    if (ref.watch(useSupabaseProvider)) {
      return SupabaseProfileRepositoryImpl(
        ref.watch(supabaseClientProvider),
      );
    }
    return ProfileRepositoryImpl(
      ref.watch(assistantProfileStoreProvider),
      ref.watch(secureCredentialsStoreProvider),
      ref.watch(passwordHasherProvider),
    );
  },
);
