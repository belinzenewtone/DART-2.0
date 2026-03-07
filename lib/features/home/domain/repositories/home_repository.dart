import 'package:dart_2_0/features/home/domain/entities/home_overview.dart';

abstract class HomeRepository {
  Stream<HomeOverview> watchOverview();
}
