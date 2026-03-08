import 'package:dart_2_0/features/analytics/domain/entities/analytics_snapshot.dart';

abstract class AnalyticsRepository {
  Stream<AnalyticsSnapshot> watchSnapshot();
}
