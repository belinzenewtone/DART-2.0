import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:beltech/core/feature_flags/feature_flag_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  test('returns defaults and applies remote values', () async {
    final store = FeatureFlagStore();

    final defaultParser = await store.isEnabled(FeatureFlag.parserV2);
    expect(defaultParser, isTrue);

    await store.applyRemoteValues({
      FeatureFlag.parserV2.key: false,
      FeatureFlag.smartNotifications.key: false,
    });

    expect(await store.isEnabled(FeatureFlag.parserV2), isFalse);
    expect(await store.isEnabled(FeatureFlag.smartNotifications), isFalse);
  });
}
