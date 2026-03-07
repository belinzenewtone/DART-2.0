import 'package:dart_2_0/features/assistant/domain/entities/assistant_message.dart';

abstract class AssistantRepository {
  Stream<List<AssistantMessage>> watchConversation();
  List<AssistantSuggestion> suggestions();

  Future<void> sendMessage(String text);
}
