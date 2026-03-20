import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static Future<void> lightImpact() async {
    if (!_enabled) {
      return;
    }
    await HapticFeedback.lightImpact();
  }
}
