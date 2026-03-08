import 'package:flutter/material.dart';

class AppFeedback {
  const AppFeedback._();

  static void success(BuildContext context, String message) {
    _show(context, message);
  }

  static void error(BuildContext context, String message) {
    _show(context, message);
  }

  static void info(BuildContext context, String message) {
    _show(context, message);
  }

  static void _show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null || message.trim().isEmpty) {
      return;
    }
    messenger.hideCurrentSnackBar();
    final keyboardInset = MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message.trim(),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 88 + keyboardInset),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
