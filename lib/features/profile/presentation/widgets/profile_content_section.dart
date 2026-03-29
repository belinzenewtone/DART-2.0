import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_capsule.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class ProfileContentSection extends StatelessWidget {
  const ProfileContentSection({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onOpenSettings,
    required this.onChangePassword,
    required this.onAvatarCameraTap,
    required this.showSignOut,
    required this.signingOut,
    required this.onSignOut,
    this.workspaceLabel = 'Local Workspace',
  });

  final UserProfile profile;
  final VoidCallback onEdit,
      onOpenSettings,
      onChangePassword,
      onAvatarCameraTap,
      onSignOut;
  final bool showSignOut, signingOut;

  /// Shown below the name in the identity card (e.g. "Local Workspace" or "Cloud Workspace")
  final String workspaceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Identity card — teal accent, matches RN reference ──────────────────
        GlassCard(
          tone: GlassCardTone.accent,
          accentColor: AppColors.accent,
          child: Column(
            children: [
              // Avatar row
              Row(
                children: [
                  ProfileAvatar(
                    name: profile.name,
                    avatarUrl: profile.avatarUrl,
                    onCameraTap: onAvatarCameraTap,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: AppTypography.sectionTitle(context).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          workspaceLabel,
                          style: AppTypography.bodySm(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        AppCapsule(
                          label: 'Member since ${profile.memberSinceLabel}',
                          color: AppColors.accent,
                          variant: AppCapsuleVariant.subtle,
                          size: AppCapsuleSize.sm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Edit Profile',
                      onPressed: onEdit,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Settings',
                      onPressed: onOpenSettings,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        // ── Security section — password + sign-out ─────────────────────────────
        GlassCard(
          tone: GlassCardTone.muted,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(GlassStyles.borderRadius),
                ),
                onTap: onChangePassword,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppColors.warning.withValues(alpha: 0.18),
                        child: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.warning, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password',
                          style: AppTypography.cardTitle(context),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ),
              ),
              if (showSignOut) ...[
                Divider(
                    height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(GlassStyles.borderRadius),
                  ),
                  onTap: signingOut ? null : onSignOut,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.danger.withValues(alpha: 0.18),
                          child: const Icon(Icons.logout_rounded,
                              color: AppColors.danger, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sign Out',
                            style: AppTypography.cardTitle(context)
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                        if (signingOut)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.danger, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
