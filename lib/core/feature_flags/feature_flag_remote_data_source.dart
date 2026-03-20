import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlagRemoteDataSource {
  FeatureFlagRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, bool>> fetchFlags() async {
    final rows = await _client
        .from('feature_flags')
        .select('flag_key, enabled')
        .eq('active', true);
    final result = <String, bool>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final key = '${row['flag_key'] ?? ''}'.trim();
      if (key.isEmpty) {
        continue;
      }
      result[key] = row['enabled'] == true;
    }
    return result;
  }
}
