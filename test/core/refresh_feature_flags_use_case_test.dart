import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_remote_data_source.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:beltech/core/feature_flags/refresh_feature_flags_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFeatureFlagRemoteDataSource extends Mock
    implements FeatureFlagRemoteDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  test('applies both remote enabled flags and rollout percentages', () async {
    final store = FeatureFlagStore();
    final remote = _MockFeatureFlagRemoteDataSource();
    when(() => remote.fetchConfig()).thenAnswer(
      (_) async => const FeatureFlagRemoteConfig(
        enabled: {'background_sync': false, 'smart_notifications': true},
        rolloutPercentage: {'background_sync': 25, 'smart_notifications': 80},
      ),
    );

    final useCase = RefreshFeatureFlagsUseCase(store, remoteDataSource: remote);

    await useCase.call();

    expect(await store.isEnabled(FeatureFlag.backgroundSync), isFalse);
    expect(await store.isEnabled(FeatureFlag.smartNotifications), isTrue);
    expect(await store.rolloutPercentage(FeatureFlag.backgroundSync), 25);
    expect(await store.rolloutPercentage(FeatureFlag.smartNotifications), 80);
  });
}
