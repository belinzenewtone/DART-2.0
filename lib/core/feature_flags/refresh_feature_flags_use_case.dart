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
    final remoteValues = await _remoteDataSource.fetchFlags();
    await _store.applyRemoteValues(remoteValues);
  }
}
