import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AuthFormIntro extends StatelessWidget {
  const AuthFormIntro({
    super.key,
    required this.isSignUp,
    required this.isLoading,
    required this.onModeChanged,
  });

  final bool isSignUp;
  final bool isLoading;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSignUp ? 'Sign up' : 'Sign in',
          style: TextStyle(
            fontSize: AppTypography.xxxl,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryFor(brightness),
            height: 38 / 32, // lineHeight 38 / fontSize 32
          ),
        ),
        const SizedBox(height: AppSpacing.sm), // margin bottom xs equivalent loosely
        Text(
          isSignUp
              ? 'Create an account to start managing your data.'
              : 'Continue with your PersonalOs workspace.',
          style: TextStyle(
            fontSize: AppTypography.md,
            color: AppColors.textSecondaryFor(brightness),
            height: 22 / 16,
          ),
        ),
      ],
    );
  }
}
