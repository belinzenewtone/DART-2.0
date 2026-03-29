import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlagRemoteConfig {
  const FeatureFlagRemoteConfig({
    required this.enabled,
    required this.rolloutPercentage,
  });

  final Map<String, bool> enabled;
  final Map<String, int> rolloutPercentage;
}

class FeatureFlagRemoteDataSource {
  FeatureFlagRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<FeatureFlagRemoteConfig> fetchConfig() async {
    final rows = await _client
        .from('feature_flags')
        .select('flag_key, enabled, rollout_percentage')
        .eq('active', true);
    final enabled = <String, bool>{};
    final rollout = <String, int>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final key = '${row['flag_key'] ?? ''}'.trim();
      if (key.isEmpty) {
        continue;
      }
      enabled[key] = row['enabled'] == true;
      rollout[key] = _parseRolloutPercentage(row['rollout_percentage']);
    }
    return FeatureFlagRemoteConfig(
      enabled: enabled,
      rolloutPercentage: rollout,
    );
  }

  Future<Map<String, bool>> fetchFlags() async {
    final config = await fetchConfig();
    return config.enabled;
  }

  int _parseRolloutPercentage(dynamic value) {
    if (value is num) {
      return value.toInt().clamp(0, 100);
    }
    final parsed = int.tryParse('$value');
    if (parsed == null) {
      return 100;
    }
    return parsed.clamp(0, 100);
  }
}
