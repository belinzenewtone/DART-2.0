import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/core/sync/sms_auto_import_service.dart';
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
