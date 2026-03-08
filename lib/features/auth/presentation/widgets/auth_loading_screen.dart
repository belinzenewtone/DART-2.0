import 'package:beltech/core/theme/glass_styles.dart';
import 'package:flutter/material.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient:
            GlassStyles.backgroundGradientFor(Theme.of(context).brightness),
      ),
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
