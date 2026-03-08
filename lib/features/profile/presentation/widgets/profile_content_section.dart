import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/profile/domain/entities/user_profile.dart';
import 'package:dart_2_0/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

class ProfileContentSection extends StatelessWidget {
  const ProfileContentSection({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onChangePassword,
    required this.onAvatarCameraTap,
    required this.showSignOut,
    required this.signingOut,
    required this.onSignOut,
  });

  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onChangePassword;
  final VoidCallback onAvatarCameraTap;
  final bool showSignOut;
  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ProfileAvatar(
            name: profile.name,
            avatarUrl: profile.avatarUrl,
            onCameraTap: onAvatarCameraTap,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(profile.name, style: textTheme.titleMedium)),
        const SizedBox(height: 6),
        Center(child: Text(profile.email, style: textTheme.bodyMedium)),
        const SizedBox(height: 16),
        GlassCard(
          child: _StatusRow(
            icon: Icons.stars_rounded,
            iconColor: AppColors.accent,
            title: 'Member Since',
            subtitle: profile.memberSinceLabel,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: _StatusRow(
            icon:
                profile.verified ? Icons.verified : Icons.warning_amber_rounded,
            iconColor: profile.verified ? AppColors.success : AppColors.warning,
            title: profile.verified ? 'Account Verified' : 'Account Pending',
            subtitle: profile.verified
                ? 'Your email has been confirmed'
                : 'Verify your email to secure the account',
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Personal Info', style: textTheme.titleMedium),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, color: AppColors.accent),
                  ),
                ],
              ),
              _InfoLine(icon: Icons.person, label: 'Name', value: profile.name),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.mail_outline,
                label: 'Email',
                value: profile.email,
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.call_outlined,
                label: 'Phone',
                value: profile.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onChangePassword,
          child: const GlassCard(
            child: _StatusRow(
              icon: Icons.lock,
              iconColor: AppColors.warning,
              title: 'Change Password',
              subtitle: 'Update your account password',
            ),
          ),
        ),
        if (showSignOut) ...[
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: signingOut ? null : onSignOut,
            child: GlassCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.danger.withValues(alpha: 0.18),
                    child: const Icon(Icons.logout, color: AppColors.danger),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sign Out'),
                        const SizedBox(height: 2),
                        Text(
                          'Sign out from this device',
                          style: TextStyle(color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  if (signingOut)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.chevron_right, color: AppColors.danger),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final infoIconBackground = brightness == Brightness.light
        ? AppColors.accent.withValues(alpha: 0.14)
        : AppColors.accentSoft;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: infoIconBackground,
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyMedium),
              Text(value, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
