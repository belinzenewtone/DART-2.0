import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_spacing.dart';
import 'package:beltech/core/widgets/app_feedback.dart';
import 'package:beltech/core/widgets/error_message.dart';
import 'package:beltech/core/widgets/glass_card.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final secondaryText = AppColors.textSecondaryFor(brightness);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final messagesState = ref.watch(assistantMessagesProvider);
    final suggestions = ref.watch(assistantSuggestionsProvider);
    final writeState = ref.watch(assistantWriteControllerProvider);
    final conversationState =
        ref.watch(assistantConversationControllerProvider);

    ref.listen<AsyncValue<void>>(assistantWriteControllerProvider,
        (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, 'Message failed to send.');
      }
    });
    ref.listen<AsyncValue<void>>(assistantConversationControllerProvider,
        (previous, next) {
      if (next.hasError) {
        AppFeedback.error(context, 'Unable to clear chat history.');
      } else if (previous?.isLoading == true && next.hasValue) {
        AppFeedback.success(context, 'Chat history cleared.');
      }
    });

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.sectionPadding(context, bottom: 0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentSoft,
                  child: Icon(Icons.smart_toy, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BELTECH Assistant', style: textTheme.titleLarge),
                    Text(
                      'Online',
                      style: textTheme.bodyMedium?.copyWith(
                        color: brightness == Brightness.light
                            ? AppColors.teal
                            : AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear chats',
                  onPressed:
                      conversationState.isLoading ? null : _confirmClearChats,
                  icon: conversationState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                16,
                AppSpacing.screenHorizontal,
                AppSpacing.contentBottomSafe + keyboardInset,
              ),
              children: [
                messagesState.when(
                  data: (messages) =>
                      AssistantConversationList(messages: messages),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => ErrorMessage(
                    label: 'Unable to load assistant',
                    onRetry: () => ref.invalidate(assistantMessagesProvider),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Try asking:',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                AssistantPromptGrid(
                  prompts: suggestions.map((item) => item.prompt).toList(),
                  onPromptTap: _sendMessage,
                ),
              ],
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + keyboardInset),
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(_messageController.text),
                      decoration: InputDecoration(
                        hintText: 'Message BELTECH...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: secondaryText),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: writeState.isLoading
                          ? null
                          : () => _sendMessage(_messageController.text),
                      icon: writeState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppColors.textPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send,
                              color: AppColors.textPrimary),
                    ),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
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
