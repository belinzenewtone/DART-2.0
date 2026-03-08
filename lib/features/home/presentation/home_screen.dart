import 'package:beltech/core/theme/app_motion.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/beltech_logo.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/features/home/presentation/providers/home_providers.dart';
import 'package:beltech/features/home/presentation/widgets/home_overview_content.dart';
import 'package:beltech/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final overviewState = ref.watch(homeOverviewProvider);
    final profileState = ref.watch(profileProvider);
    final firstName = profileState.valueOrNull?.name.trim().split(' ').first;
    final greeting = _buildGreeting(firstName);
    final contentSwitchDuration =
        AppMotion.duration(context, normalMs: 180, reducedMs: 0);
    final overviewChild = overviewState.when(
      data: (overview) => KeyedSubtree(
        key: const ValueKey<String>('overview-data'),
        child: HomeOverviewContent(overview: overview),
      ),
      loading: () => const KeyedSubtree(
        key: ValueKey<String>('overview-loading'),
        child: Center(child: LoadingIndicator()),
      ),
      error: (_, __) => KeyedSubtree(
        key: const ValueKey<String>('overview-error'),
        child: ErrorMessage(
          label: 'Unable to load dashboard',
          onRetry: () => ref.invalidate(homeOverviewProvider),
        ),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BeltechLogo(size: 38, borderRadius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(greeting, style: textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("Here's your day at a glance", style: textTheme.bodyMedium),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: contentSwitchDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: overviewChild,
            ),
          ],
        ),
      ),
    );
  }

  String _buildGreeting(String? firstName) {
    final hour = DateTime.now().hour;
    final salutation = switch (hour) {
      >= 5 && < 12 => 'Good Morning',
      >= 12 && < 17 => 'Good Afternoon',
      >= 17 && < 21 => 'Good Evening',
      _ => 'Good Night',
    };
    if (firstName == null || firstName.isEmpty) {
      return salutation;
    }
    return '$salutation, $firstName';
  }
}
