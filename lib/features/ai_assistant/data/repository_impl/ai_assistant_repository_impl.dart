import 'package:expense_management/features/ai_assistant/data/data_source/remote/ai_assistant_api_service.dart';
import 'package:expense_management/features/ai_assistant/domain/entities/ai_assistant_entities.dart';
import 'package:expense_management/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  final AiAssistantApiService _apiService;

  AiAssistantRepositoryImpl(this._apiService);

  @override
  Future<List<AiConversation>> getConversations() async {
    final response = await _apiService.getConversations();
    if (response['success'] == true) {
      final list = (response['conversations'] as List)
          .map((item) => AiConversation.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } else {
      throw Exception(response['error'] ?? 'Lỗi tải danh sách cuộc hội thoại.');
    }
  }

  @override
  Future<void> deleteConversation(String id) async {
    final response = await _apiService.deleteConversation(id);
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Lỗi khi xóa cuộc hội thoại.');
    }
  }

  @override
  Future<void> renameConversation(String id, String newTitle) async {
    final response = await _apiService.renameConversation(id, {
      'title': newTitle,
    });
    if (response['success'] != true) {
      throw Exception(response['error'] ?? 'Lỗi khi sửa tên cuộc hội thoại.');
    }
  }

  @override
  Future<Map<String, dynamic>> sendChatMessage({
    required String prompt,
    String? conversationId,
  }) async {
    final payload = {
      'prompt': prompt,
      if (conversationId != null) 'conversation_id': conversationId,
    };
    final response = await _apiService.sendChatMessage(payload);
    if (response['success'] == true) {
      return response;
    } else {
      throw Exception(response['error'] ?? 'Đã xảy ra lỗi khi gọi AI.');
    }
  }

  @override
  Future<Map<String, dynamic>> getConversationMessages(String id) async {
    final response = await _apiService.getConversationMessages(id);
    if (response['success'] == true) {
      return response;
    } else {
      throw Exception(response['error'] ?? 'Lỗi tải cuộc hội thoại.');
    }
  }
}
