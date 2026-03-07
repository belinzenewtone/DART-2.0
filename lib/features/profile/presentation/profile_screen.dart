import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/auth/presentation/providers/account_providers.dart';
import 'package:dart_2_0/features/profile/presentation/providers/profile_providers.dart';
import 'package:dart_2_0/features/profile/presentation/widgets/profile_content_section.dart';
import 'package:dart_2_0/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:dart_2_0/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });
    ref.listen<AsyncValue<void>>(accountAuthControllerProvider,
        (previous, next) {
      if (next.hasError) {
        final message = '${next.error}'.replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile', style: textTheme.titleLarge),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
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
                showSignOut: useSupabase,
                signingOut: authWriteState.isLoading,
                onSignOut: () async {
                  await ref.read(accountAuthControllerProvider.notifier).signOut();
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const ProfileErrorCard(label: 'Unable to load profile'),
            ),
          ],
        ),
      ),
    );
  }
}
