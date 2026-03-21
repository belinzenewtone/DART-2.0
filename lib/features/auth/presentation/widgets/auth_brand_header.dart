import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/beltech_logo.dart';
import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _RetainedAuthIcons(),
        Stack(
          alignment: Alignment.center,
          children: [
            IgnorePointer(
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.glowBlue, Colors.transparent],
                    radius: 0.75,
                  ),
                ),
              ),
            ),
            const BeltechLogo(size: 80, borderRadius: 20),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'BELTECH',
          style: AppTypography.pageTitle(context).copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Secure personal workspace',
          style: AppTypography.bodySm(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RetainedAuthIcons extends StatelessWidget {
  const _RetainedAuthIcons();

  @override
  Widget build(BuildContext context) {
    return const Offstage(
      offstage: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded),
          Icon(Icons.rocket_launch_outlined),
          Icon(Icons.lock_open_rounded),
          Icon(Icons.shield_outlined),
        ],
      ),
    );
  }
}
