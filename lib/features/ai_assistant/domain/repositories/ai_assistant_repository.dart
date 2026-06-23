import 'package:expense_management/features/ai_assistant/domain/entities/ai_assistant_entities.dart';

abstract class AiAssistantRepository {
  Future<List<AiConversation>> getConversations();
  Future<void> deleteConversation(String id);
  Future<void> renameConversation(String id, String newTitle);
  Future<Map<String, dynamic>> sendChatMessage({required String prompt, String? conversationId});
  Future<Map<String, dynamic>> getConversationMessages(String id);
}
