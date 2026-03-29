import 'dart:io';

import 'package:beltech/core/navigation/shell_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class ScreenCaptureProtectionService {
  const ScreenCaptureProtectionService._();

  static bool _isSensitiveTab(int tabIndex) {
    return tabIndex == ShellTab.finance.index ||
        tabIndex == ShellTab.profile.index;
  }

  static Future<void> syncForTab(int tabIndex) async {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }
    try {
      if (_isSensitiveTab(tabIndex)) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } else {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } catch (_) {
      return;
    }
  }
}
