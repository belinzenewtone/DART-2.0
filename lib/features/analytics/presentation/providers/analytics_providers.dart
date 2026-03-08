import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((_) => AnalyticsPeriod.week);

final analyticsSnapshotProvider = StreamProvider<AnalyticsSnapshot>(
  (ref) => ref.watch(analyticsRepositoryProvider).watchSnapshot(),
);
