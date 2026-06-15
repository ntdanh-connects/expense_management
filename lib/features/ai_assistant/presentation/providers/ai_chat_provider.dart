import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:flutter_riverpod/legacy.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  AiChatState({
    required this.messages,
    required this.isLoading,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref ref;

  AiChatNotifier(this.ref)
      : super(AiChatState(messages: [], isLoading: false)) {
    // Thêm tin nhắn chào hỏi ban đầu từ AI
    state = AiChatState(
      messages: [
        ChatMessage(
          text: 'Xin chào! Tôi là EM AI Assistant. Tôi có thể giúp gì cho bạn về quản lý tài chính và chi tiêu hôm nay? ✨',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post('api/ai-chat', data: {
        'prompt': text,
      });

      if (response.data != null && response.data['success'] == true) {
        final botResponse = response.data['response'] ?? 'Không có phản hồi từ AI.';
        final botMessage = ChatMessage(
          text: botResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, botMessage],
          isLoading: false,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Đã xảy ra lỗi khi gọi AI.');
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Có lỗi xảy ra: Không thể kết nối đến Trợ lý AI. Vui lòng thử lại sau.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = AiChatState(
      messages: [
        ChatMessage(
          text: 'Xin chào! Tôi là EM AI Assistant. Tôi có thể giúp gì cho bạn về quản lý tài chính và chi tiêu hôm nay? ✨',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
    );
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});
