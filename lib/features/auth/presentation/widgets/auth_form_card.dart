import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/features/auth/presentation/widgets/auth_form_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.formKey,
    required this.isSignUp,
    required this.isLoading,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.hidePassword,
    required this.hideConfirmPassword,
    required this.onTogglePasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.onSubmit,
    required this.onModeChanged,
  });

  final GlobalKey<FormState> formKey;
  final bool isSignUp;
  final bool isLoading;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool hidePassword;
  final bool hideConfirmPassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final VoidCallback onSubmit;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final resizeDuration = AppMotion.duration(
      context,
      normalMs: 180,
      reducedMs: 0,
    );
    final sectionDuration = AppMotion.duration(
      context,
      normalMs: 160,
      reducedMs: 0,
    );

    return Form(
      key: formKey,
      child: AutofillGroup(
        child: AnimatedSize(
          duration: resizeDuration,
          curve: Curves.easeOutCubic,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthFormIntro(
                isSignUp: isSignUp,
                isLoading: isLoading,
                onModeChanged: onModeChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedSwitcher(
                duration: sectionDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: isSignUp
                    ? Column(
                        key: const ValueKey<String>('signup-fields'),
                        children: [
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'Choose a short username',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) {
                              if (!isSignUp) return null;
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Username is required';
                              if (v.length > 10) return 'Max 10 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: phoneController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              hintText: '07XXXXXXXX',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              if (!isSignUp) return null;
                              final phone = value?.trim() ?? '';
                              if (phone.isEmpty) return 'Phone is required';
                              if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                                return 'Phone must be exactly 10 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey<String>('signin-fields'),
                      ),
              ),
              TextFormField(
                controller: emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Valid email is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                textInputAction:
                    isSignUp ? TextInputAction.next : TextInputAction.done,
                obscureText: hidePassword,
                autofillHints: [
                  isSignUp
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                onFieldSubmitted: (_) {
                  if (!isSignUp && !isLoading) onSubmit();
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: isSignUp
                      ? 'Create a secure password'
                      : '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: onTogglePasswordVisibility,
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              AnimatedSwitcher(
                duration: sectionDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: isSignUp
                    ? Column(
                        key: const ValueKey<String>('confirm-password'),
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: confirmPasswordController,
                            textInputAction: TextInputAction.done,
                            obscureText: hideConfirmPassword,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) {
                              if (!isLoading) onSubmit();
                            },
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: onToggleConfirmPasswordVisibility,
                                icon: Icon(
                                  hideConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (!isSignUp) return null;
                              if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey<String>('no-confirm-password'),
                      ),
              ),
              if (!isSignUp) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to forgot password screen when implemented
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: AppTypography.sm,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: isSignUp ? 'Sign Up' : 'Sign In',
                onPressed: isLoading ? null : onSubmit,
                loading: isLoading,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.lg,
                fullWidth: true,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignUp
                        ? 'Already have an account? '
                        : 'Don\'t have an account? ',
                    style: TextStyle(
                      fontSize: AppTypography.sm,
                      color: AppColors.textSecondaryFor(Theme.of(context).brightness),
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () => onModeChanged(!isSignUp),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        isSignUp ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: AppTypography.sm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
