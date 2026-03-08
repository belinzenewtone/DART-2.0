import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/core/sync/background_sync_coordinator.dart';
import 'package:dart_2_0/core/sync/sms_auto_import_service.dart';
import 'package:dart_2_0/features/recurring/data/services/recurring_materializer_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smsAutoImportServiceProvider = Provider<SmsAutoImportService>((ref) {
  final service = SmsAutoImportService(
    ref.watch(expensesRepositoryProvider),
    ref.watch(accountRepositoryProvider),
  );
  ref.onDispose(() {
    service.stop();
  });
  return service;
});

final recurringMaterializerServiceProvider =
    Provider<RecurringMaterializerService>((ref) {
  final service = RecurringMaterializerService(
    ref.watch(recurringRepositoryProvider),
  );
  ref.onDispose(() {
    service.stop();
  });
  return service;
});

final backgroundSyncCoordinatorProvider =
    Provider<BackgroundSyncCoordinator>((ref) {
  final coordinator = BackgroundSyncCoordinator(
    ref.watch(smsAutoImportServiceProvider),
    ref.watch(recurringMaterializerServiceProvider),
  );
  ref.onDispose(() {
    coordinator.stop();
  });
  return coordinator;
});
