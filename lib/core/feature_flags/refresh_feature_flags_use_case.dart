import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/feature_flags/feature_flag_remote_data_source.dart';

class RefreshFeatureFlagsUseCase {
  RefreshFeatureFlagsUseCase(
    this._store, {
    FeatureFlagRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final FeatureFlagStore _store;
  final FeatureFlagRemoteDataSource? _remoteDataSource;

  Future<void> call() async {
    if (_remoteDataSource == null) {
      return;
    }
    final remoteConfig = await _remoteDataSource.fetchConfig();
    await _store.applyRemoteValues(remoteConfig.enabled);
    await _store.applyRemoteRollout(remoteConfig.rolloutPercentage);
  }
}
