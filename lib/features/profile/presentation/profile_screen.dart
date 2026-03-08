import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/features/auth/presentation/providers/account_providers.dart';
import 'package:beltech/features/profile/presentation/providers/profile_providers.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_content_section.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final profileState = ref.watch(profileProvider);
    final authWriteState = ref.watch(accountAuthControllerProvider);
    final useSupabase = ref.watch(useSupabaseProvider);

    ref.listen<AsyncValue<void>>(profileWriteControllerProvider,
        (previous, next) {
      if (previous is AsyncLoading && next is AsyncData<void>) {
        AppFeedback.success(context, 'Profile updated successfully.');
      } else if (next.hasError) {
        AppFeedback.error(
            context, '${next.error}'.replaceFirst('Exception: ', ''));
      }
    });
    ref.listen<AsyncValue<void>>(accountAuthControllerProvider,
        (previous, next) {
      if (next.hasError) {
        final message = '${next.error}'.replaceFirst('Exception: ', '');
        AppFeedback.error(context, message);
      }
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile', style: textTheme.titleLarge),
                IconButton(
                  onPressed: () {
                    context.pushNamed('settings');
                  },
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 18),
            profileState.when(
              data: (profile) => ProfileContentSection(
                profile: profile,
                onEdit: () => showEditProfileDialog(context, ref, profile),
                onChangePassword: () => showPasswordDialog(context, ref),
                onAvatarCameraTap: () async {
                  try {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      maxHeight: 1024,
                      imageQuality: 88,
                    );
                    if (picked == null) {
                      return;
                    }
                    final bytes = await picked.readAsBytes();
                    final extension =
                        p.extension(picked.path).replaceFirst('.', '');
                    await ref
                        .read(profileWriteControllerProvider.notifier)
                        .updateAvatar(
                          bytes: bytes,
                          fileExtension: extension.isEmpty ? 'jpeg' : extension,
                        );
                    if (!context.mounted) {
                      return;
                    }
                    final writeState = ref.read(profileWriteControllerProvider);
                    if (!writeState.hasError) {
                      AppFeedback.success(
                          context, 'Profile photo updated successfully.');
                    }
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    final message = '$error'.replaceFirst('Exception: ', '');
                    AppFeedback.error(context, message);
                  }
                },
                showSignOut: useSupabase,
                signingOut: authWriteState.isLoading,
                onSignOut: () async {
                  await ref
                      .read(accountAuthControllerProvider.notifier)
                      .signOut();
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ErrorMessage(
                label: 'Unable to load profile',
                onRetry: () => ref.invalidate(profileProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
