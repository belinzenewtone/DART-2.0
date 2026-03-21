import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
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
        SegmentedButton<bool>(
          showSelectedIcon: false,
          selected: {isSignUp},
          onSelectionChanged:
              isLoading ? null : (selection) => onModeChanged(selection.first),
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.login_rounded),
              label: Text('Sign In'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.person_add_alt_1_rounded),
              label: Text('Sign Up'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppCapsule(
              label:
                  isSignUp ? 'Create your workspace' : 'Access your workspace',
              color: AppColors.accent,
              icon: isSignUp
                  ? Icons.rocket_launch_outlined
                  : Icons.lock_open_rounded,
              variant: AppCapsuleVariant.subtle,
              size: AppCapsuleSize.md,
            ),
            const AppCapsule(
              label: 'Smooth secure flow',
              color: AppColors.teal,
              icon: Icons.shield_outlined,
              variant: AppCapsuleVariant.subtle,
              size: AppCapsuleSize.md,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isSignUp ? 'Create Account' : 'Welcome Back',
          style: AppTypography.sectionTitle(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          isSignUp
              ? 'Set up your profile once and keep everything in one place.'
              : 'Sign in to continue with your personal workspace.',
          style: AppTypography.bodySm(context).copyWith(
            color: AppColors.textMutedFor(brightness),
          ),
        ),
      ],
    );
  }
}
