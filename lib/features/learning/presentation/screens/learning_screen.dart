import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/core/layout/secondary_page_shell.dart';
import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/features/learning/domain/entities/learning_session.dart';
import 'package:beltech/features/learning/presentation/widgets/learning_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _learningProvider = StreamProvider<List<LearningSession>>((ref) =>
    ref.watch(learningRepositoryProvider).watchSessions());

final _learningStreakProvider = FutureProvider<int>((ref) =>
    ref.watch(learningRepositoryProvider).currentStreak());

final _learningMonthlyProvider = FutureProvider<int>((ref) =>
    ref.watch(learningRepositoryProvider).monthlyMinutes(DateTime.now()));

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_learningProvider);
    final streakAsync = ref.watch(_learningStreakProvider);
    final monthlyAsync = ref.watch(_learningMonthlyProvider);
    return SecondaryPageShell(
      title: 'Learning',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Icon(Icons.local_fire_department, color: AppColors.warning),
                          const SizedBox(height: 4),
                          Text(
                            streakAsync.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '0'),
                            style: AppTypography.headlineSm(context).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text('Day streak', style: AppTypography.bodySm(context)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.accent),
                          const SizedBox(height: 4),
                          Text(
                            monthlyAsync.when(data: (v) => '$v', loading: () => '...', error: (_, __) => '0'),
                            style: AppTypography.headlineSm(context).copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text('Min this month', style: AppTypography.bodySm(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(child: Text('No sessions yet'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, i) {
                    final s = sessions[i];
                    return GlassCard(
                      child: ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: Text(s.topic, style: AppTypography.bodyMd(context).copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('${s.durationMinutes} min · ${_fmtDate(s.date)}', style: AppTypography.bodySm(context)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => ref.read(learningRepositoryProvider).deleteSession(s.id),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Session'),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LearningFormSheet(),
    );
  }
}
