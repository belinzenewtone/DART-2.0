import 'dart:async';

import 'package:dart_2_0/core/di/repository_providers.dart';
import 'package:dart_2_0/features/assistant/domain/entities/assistant_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assistantMessagesProvider = StreamProvider<List<AssistantMessage>>(
  (ref) => ref.watch(assistantRepositoryProvider).watchConversation(),
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
