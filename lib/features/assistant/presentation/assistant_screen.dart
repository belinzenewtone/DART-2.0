import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/theme/app_typography.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
import 'package:beltech/core/widgets/loading_indicator.dart';
import 'package:beltech/core/widgets/page_header.dart';
import 'package:beltech/core/widgets/page_shell.dart';
import 'package:beltech/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:beltech/features/assistant/presentation/widgets/assistant_conversation.dart';
import 'package:beltech/features/assistant/presentation/widgets/assistant_prompt_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final messagesState = ref.watch(assistantMessagesProvider);
    final suggestions = ref.watch(assistantSuggestionsProvider);
    final writeState = ref.watch(assistantWriteControllerProvider);
    final conversationState =
        ref.watch(assistantConversationControllerProvider);

    ref.listen<AsyncValue<void>>(assistantWriteControllerProvider,
        (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, 'Message failed to send.', ref: ref);
      }
    });
    ref.listen<AsyncValue<void>>(assistantConversationControllerProvider,
        (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to clear chat history.', ref: ref);
      } else if (previous?.isLoading == true && next.hasValue) {
        AppFeedback.success(context, 'Chat history cleared.', ref: ref);
      }
    });

    final hasMessages = messagesState.valueOrNull?.isNotEmpty ?? false;

    // bottomPadding: 0 lets the composer sit flush just above the tab bar.
    // PageShell's non-scrollable branch will add safeBottom automatically.
    return PageShell(
      glowColor: AppColors.glowViolet,
      scrollable: false,
      bottomPadding: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            eyebrow: 'AI COACH',
            title: 'Assistant',
            subtitle: 'Online',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasMessages) ...[
                  _AssistantPillButton(
                    icon: Icons.chat_outlined,
                    label: '+ New chat',
                    onTap: conversationState.isLoading
                        ? null
                        : _confirmClearChats,
                  ),
                ] else ...[
                  _AssistantPillButton(
                    icon: Icons.article_outlined,
                    label: 'Brief',
                    onTap: null,
                  ),
                  const SizedBox(width: 8),
                  _AssistantPillButton(
                    icon: Icons.add_rounded,
                    label: 'New chat',
                    onTap: null,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                0,
                0,
                0,
                AppSpacing.sectionGap,
              ),
              children: [
                // Quick prompt suggestions — horizontal scroll row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  child: AssistantPromptGrid(
                    prompts: suggestions.map((item) => item.prompt).toList(),
                    onPromptTap: _sendMessage,
                  ),
                ),
                const SizedBox(height: 14),
                messagesState.when(
                  data: (messages) =>
                      AssistantConversationList(messages: messages),
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (_, __) => ErrorMessage(
                    label: 'Unable to load assistant',
                    onRetry: () => ref.invalidate(assistantMessagesProvider),
                  ),
                ),
              ],
            ),
          ),
          // ── Composer sits directly above the floating tab bar ────────────
          // Horizontal padding is inherited from PageShell (screenHorizontal).
          // Only a small top gap and minimal bottom clearance are added here.
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
            child: GlassCard(
              tone: GlassCardTone.muted,
              borderRadius: AppRadius.xxl,
              padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(_messageController.text),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message Assistant…',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        hintStyle: TextStyle(
                          color: secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SendButton(
                    loading: writeState.isLoading,
                    onTap: () => _sendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    final payload = text.trim();
    if (payload.isEmpty) {
      return;
    }
    _messageController.clear();
    await ref
        .read(assistantWriteControllerProvider.notifier)
        .sendMessage(payload);
  }

  Future<void> _confirmClearChats() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chats'),
        content: const Text(
          'This will remove previous assistant messages from this account.',
        ),
        actions: [
          AppButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(false),
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.sm,
          ),
          AppButton(
            label: 'Clear',
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
    if (shouldClear != true || !mounted) {
      return;
    }
    await ref
        .read(assistantConversationControllerProvider.notifier)
        .clearConversation();
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

/// Rounded pill button used in the AssistantScreen header (Brief / New chat).
class _AssistantPillButton extends StatelessWidget {
  const _AssistantPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(brightness),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: AppColors.borderFor(brightness).withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teal send button matching the React Native assistant composer.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: loading
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
        ),
      ),
    );
  }
}
