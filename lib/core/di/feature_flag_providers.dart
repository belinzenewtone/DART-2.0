import 'package:beltech/core/config/supabase_config.dart';
import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_remote_data_source.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/feature_flags/refresh_feature_flags_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final featureFlagStoreProvider = Provider<FeatureFlagStore>(
  (_) => FeatureFlagStore(),
);

final featureFlagRemoteDataSourceProvider =
    Provider<FeatureFlagRemoteDataSource?>((_) {
      if (!SupabaseConfig.isConfigured) {
        return null;
      }
      return FeatureFlagRemoteDataSource(Supabase.instance.client);
    });

final refreshFeatureFlagsUseCaseProvider = Provider<RefreshFeatureFlagsUseCase>(
  (ref) => RefreshFeatureFlagsUseCase(
    ref.watch(featureFlagStoreProvider),
    remoteDataSource: ref.watch(featureFlagRemoteDataSourceProvider),
  ),
);

final featureFlagSnapshotProvider = FutureProvider<Map<FeatureFlag, bool>>(
  (ref) => ref.watch(featureFlagStoreProvider).snapshot(),
);

final featureFlagProvider = FutureProvider.family<bool, FeatureFlag>((
  ref,
  flag,
) async {
  final snapshot = await ref.watch(featureFlagSnapshotProvider.future);
  return snapshot[flag] ?? flag.defaultEnabled;
});
