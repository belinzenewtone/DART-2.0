import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/search/domain/entities/global_search_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalSearchQueryProvider = StateProvider<String>((_) => '');

final globalSearchResultsProvider =
    FutureProvider<List<GlobalSearchResult>>((ref) {
  final query = ref.watch(globalSearchQueryProvider);
  return ref.watch(globalSearchRepositoryProvider).search(query);
});
