import 'package:dart_2_0/core/theme/app_colors.dart';
import 'package:dart_2_0/core/widgets/glass_card.dart';
import 'package:dart_2_0/features/assistant/domain/entities/assistant_message.dart';
import 'package:dart_2_0/features/assistant/presentation/providers/assistant_providers.dart';
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
    final messagesState = ref.watch(assistantMessagesProvider);
    final suggestions = ref.watch(assistantSuggestionsProvider);
    final writeState = ref.watch(assistantWriteControllerProvider);

    ref.listen<AsyncValue<void>>(assistantWriteControllerProvider,
        (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    });

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                messagesState.when(
                  data: (messages) => _ConversationList(messages: messages),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const _ErrorCard(label: 'Unable to load assistant'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Try asking:',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 20),
                ),
                const SizedBox(height: 12),
                _PromptGrid(
                  prompts: suggestions.map((item) => item.prompt).toList(),
                  onPromptTap: _sendMessage,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(_messageController.text),
                      decoration: const InputDecoration(
                        hintText: 'Message BELTECH...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppColors.textSecondary),
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
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.messages});

  final List<AssistantMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: messages
          .map((message) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MessageBubble(message: message),
              ))
          .toList(),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final screenWidth = MediaQuery.of(context).size.width;

    if (message.isUser) {
      return Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.82),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentStrong],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _displayText(message.text),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.accentSoft,
            child: Icon(
              Icons.smart_toy,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
            child: GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                _displayText(message.text),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayText(String text) {
    return text.replaceAll('**', '').trim();
  }
}

class _PromptGrid extends StatelessWidget {
  const _PromptGrid({
    required this.prompts,
    required this.onPromptTap,
  });

  final List<String> prompts;
  final Future<void> Function(String) onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: prompts.map((prompt) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onPromptTap(prompt),
            child: GlassCard(
              borderRadius: 20,
              child: Text(
                prompt,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
