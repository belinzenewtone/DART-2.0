import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/beltech_logo.dart';
import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        ),
        const SizedBox(height: 12),
        const AppCapsule(
          label: 'Clean. Private. Always in sync.',
          color: AppColors.accent,
          icon: Icons.auto_awesome_rounded,
          variant: AppCapsuleVariant.subtle,
          size: AppCapsuleSize.md,
        ),
      ],
    );
  }
}
