import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/home/domain/entities/home_overview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeOverviewProvider = StreamProvider<HomeOverview>(
  (ref) => ref.watch(homeRepositoryProvider).watchOverview(),
);
