import 'dart:async';

import 'package:beltech/core/di/repository_providers.dart';
import 'package:beltech/features/assistant/domain/entities/assistant_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _assistantIntroMessage =
    "Hey! I'm your BELTECH assistant. Ask me about spending, tasks, or schedule.";

final assistantMessagesProvider = StreamProvider<List<AssistantMessage>>(
  (ref) => ref
      .watch(assistantRepositoryProvider)
      .watchConversation()
      .map(_dedupeAssistantIntroMessage),
);

final assistantSuggestionsProvider = Provider<List<AssistantSuggestion>>(
  (ref) => ref.watch(assistantRepositoryProvider).suggestions(),
);

class AssistantWriteController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> sendMessage(String text) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(assistantRepositoryProvider).sendMessage(text);
    });
  }
}

final assistantWriteControllerProvider =
    AutoDisposeAsyncNotifierProvider<AssistantWriteController, void>(
  AssistantWriteController.new,
);

List<AssistantMessage> _dedupeAssistantIntroMessage(
  List<AssistantMessage> messages,
) {
  var introSeen = false;
  final normalized = <AssistantMessage>[];
  for (final message in messages) {
    final isIntro = !message.isUser &&
        message.text.trim().toLowerCase() ==
            _assistantIntroMessage.toLowerCase();
    if (isIntro) {
      if (introSeen) {
        continue;
      }
      introSeen = true;
    }
    normalized.add(message);
  }
  return normalized;
}
