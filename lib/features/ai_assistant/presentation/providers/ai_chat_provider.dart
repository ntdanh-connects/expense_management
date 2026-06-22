import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:flutter_riverpod/legacy.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? insight;
  final List<String> suggestedQuestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.insight,
    this.suggestedQuestions = const [],
  });
}

class AiConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class AiConversationsState {
  final List<AiConversation> conversations;
  final bool isLoading;
  final String? errorMessage;

  AiConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AiConversationsState copyWith({
    List<AiConversation>? conversations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AiConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AiConversationsNotifier extends StateNotifier<AiConversationsState> {
  final Ref ref;

  AiConversationsNotifier(this.ref) : super(AiConversationsState()) {
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('api/ai-conversations');
      if (response.data != null && response.data['success'] == true) {
        final list = (response.data['conversations'] as List)
            .map((item) => AiConversation.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(conversations: list, isLoading: false);
      } else {
        throw Exception(response.data['error'] ?? 'Lỗi tải danh sách cuộc hội thoại.');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải lịch sử trò chuyện.',
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final dio = ref.read(dioClientProvider);
    final response = await dio.delete('api/ai-conversations/$conversationId');
    if (response.data != null && response.data['success'] == true) {
      // Nếu cuộc hội thoại bị xóa trùng với cuộc hội thoại hiện tại, bắt đầu chat mới
      final currentChat = ref.read(aiChatProvider);
      if (currentChat.currentConversationId == conversationId) {
        ref.read(aiChatProvider.notifier).startNewChat();
      }
      await fetchConversations();
    } else {
      throw Exception(response.data['error'] ?? 'Lỗi khi xóa cuộc hội thoại.');
    }
  }

  Future<void> renameConversation(String conversationId, String newTitle) async {
    final dio = ref.read(dioClientProvider);
    final response = await dio.put('api/ai-conversations/$conversationId', data: {
      'title': newTitle,
    });
    if (response.data != null && response.data['success'] == true) {
      // Cập nhật tiêu đề nếu là cuộc hội thoại hiện tại
      final currentChatNotifier = ref.read(aiChatProvider.notifier);
      final currentChat = ref.read(aiChatProvider);
      if (currentChat.currentConversationId == conversationId) {
        currentChatNotifier.state = currentChat.copyWith(
          conversationTitle: () => newTitle,
        );
      }
      await fetchConversations();
    } else {
      throw Exception(response.data['error'] ?? 'Lỗi khi sửa tên cuộc hội thoại.');
    }
  }
}

final aiConversationsProvider =
    StateNotifierProvider<AiConversationsNotifier, AiConversationsState>((ref) {
  return AiConversationsNotifier(ref);
});

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? currentConversationId;
  final String? conversationTitle;

  AiChatState({
    required this.messages,
    required this.isLoading,
    this.currentConversationId,
    this.conversationTitle,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? Function()? currentConversationId,
    String? Function()? conversationTitle,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentConversationId: currentConversationId != null ? currentConversationId() : this.currentConversationId,
      conversationTitle: conversationTitle != null ? conversationTitle() : this.conversationTitle,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref ref;

  AiChatNotifier(this.ref)
      : super(AiChatState(messages: [], isLoading: false)) {
    startNewChat();
  }

  void startNewChat() {
    state = AiChatState(
      messages: [
        ChatMessage(
          text: 'Xin chào! Tôi là EM AI Assistant. Tôi có thể giúp gì cho bạn về quản lý tài chính và chi tiêu hôm nay? ✨',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
      isLoading: false,
      currentConversationId: null,
      conversationTitle: null,
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
      
      final payload = {
        'prompt': text,
        if (state.currentConversationId != null) 'conversation_id': state.currentConversationId,
      };

      final response = await dio.post('api/ai-chat', data: payload);

      if (response.data != null && response.data['success'] == true) {
        final answer = response.data['answer'] ?? response.data['response'] ?? 'Không có phản hồi từ AI.';
        final insight = response.data['insight'];
        final List<String> suggestedQuestions = List<String>.from(response.data['suggested_questions'] ?? []);
        final newConversationId = response.data['conversation_id'] as String?;

        final botMessage = ChatMessage(
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
          insight: insight,
          suggestedQuestions: suggestedQuestions,
        );

        state = state.copyWith(
          messages: [...state.messages, botMessage],
          isLoading: false,
          currentConversationId: newConversationId != null ? () => newConversationId : null,
        );

        // Kích hoạt tải lại danh sách hội thoại
        ref.read(aiConversationsProvider.notifier).fetchConversations();
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

  Future<void> loadConversation(String conversationId) async {
    state = state.copyWith(isLoading: true);

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('api/ai-conversations/$conversationId/messages');

      if (response.data != null && response.data['success'] == true) {
        final conversationData = response.data['conversation'] as Map<String, dynamic>;
        final title = conversationData['title'] as String?;
        final rawMessages = response.data['messages'] as List;

        final List<ChatMessage> loadedMessages = [];

        for (final msg in rawMessages) {
          final role = msg['role'] as String;
          final functionName = msg['function_name'] as String?;
          final content = msg['content'] as String;
          final createdAt = DateTime.tryParse(msg['created_at'] as String? ?? '') ?? DateTime.now();

          if (role == 'user') {
            loadedMessages.add(ChatMessage(
              text: content,
              isUser: true,
              timestamp: createdAt,
            ));
          } else if (role == 'model' && functionName == null) {
            // Parse content dưới dạng JSON (Gemini Response)
            String text = content;
            String? insight;
            List<String> suggestedQuestions = [];

            try {
              String cleanedContent = content.trim();
              if (cleanedContent.startsWith('```json')) {
                cleanedContent = cleanedContent.substring(7);
              }
              if (cleanedContent.endsWith('```')) {
                cleanedContent = cleanedContent.substring(0, cleanedContent.length - 3);
              }
              cleanedContent = cleanedContent.trim();

              final parsed = jsonDecode(cleanedContent) as Map<String, dynamic>;
              text = parsed['answer'] ?? parsed['response'] ?? text;
              insight = parsed['insight'];
              suggestedQuestions = List<String>.from(parsed['suggested_questions'] ?? []);
            } catch (_) {
              // Bỏ qua lỗi parse, sử dụng content thô
            }

            loadedMessages.add(ChatMessage(
              text: text,
              isUser: false,
              timestamp: createdAt,
              insight: insight,
              suggestedQuestions: suggestedQuestions,
            ));
          }
        }

        // Nếu không có tin nhắn nào được hiển thị, thêm tin chào mặc định
        if (loadedMessages.isEmpty) {
          loadedMessages.add(ChatMessage(
            text: 'Xin chào! Tôi là EM AI Assistant. Tôi có thể giúp gì cho bạn về quản lý tài chính và chi tiêu hôm nay? ✨',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        }

        state = AiChatState(
          messages: loadedMessages,
          isLoading: false,
          currentConversationId: conversationId,
          conversationTitle: title,
        );
      } else {
        throw Exception(response.data['error'] ?? 'Lỗi tải cuộc hội thoại.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void clearChat() {
    startNewChat();
  }
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});
