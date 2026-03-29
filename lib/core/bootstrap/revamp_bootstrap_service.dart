import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/data/local/drift/app_drift_store.dart';
import 'package:beltech/data/local/drift/assistant_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevampBootstrapService {
  RevampBootstrapService(this._driftStore, this._assistantProfileStore);

  static const String _doneKey = 'revamp_bootstrap_v2_done';

  final AppDriftStore _driftStore;
  final AssistantProfileStore _assistantProfileStore;

  Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_doneKey) == true) {
      return;
    }
    final preservedDataMode = prefs.getString(dataModePreferenceKey);
    await _driftStore.resetAllData();
    await _assistantProfileStore.resetProfileData();
    final keys = prefs.getKeys().toList(growable: false);
    for (final key in keys) {
      if (key == _doneKey || key == dataModePreferenceKey) {
        continue;
      }
      await prefs.remove(key);
    }
    if (preservedDataMode != null) {
      await prefs.setString(dataModePreferenceKey, preservedDataMode);
    }
    await prefs.setBool(_doneKey, true);
  }
}
