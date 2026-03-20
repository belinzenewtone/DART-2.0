import 'package:beltech/core/feature_flags/feature_flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlagStore {
  static const String _keyPrefix = 'feature_flag';

  Future<bool> isEnabled(FeatureFlag flag) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(flag)) ?? flag.defaultEnabled;
  }

  Future<Map<FeatureFlag, bool>> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <FeatureFlag, bool>{};
    for (final flag in FeatureFlag.values) {
      result[flag] = prefs.getBool(_key(flag)) ?? flag.defaultEnabled;
    }
    return result;
  }

  Future<void> setValue({
    required FeatureFlag flag,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(flag), enabled);
  }

  Future<void> applyRemoteValues(Map<String, bool> values) async {
    if (values.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      final flag = FeatureFlag.fromKey(entry.key);
      if (flag == null) {
        continue;
      }
      await prefs.setBool(_key(flag), entry.value);
    }
  }

  String _key(FeatureFlag flag) => '$_keyPrefix.${flag.key}';
}
