import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:expense_management/features/ai_assistant/domain/entities/ai_assistant_entities.dart';
export 'package:expense_management/features/ai_assistant/domain/entities/ai_assistant_entities.dart';
import 'package:expense_management/features/ai_assistant/domain/di/domain_providers.dart';
import 'package:expense_management/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

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
      final repository = ref.read(aiAssistantRepositoryProvider);
      final list = await repository.getConversations();
      state = state.copyWith(conversations: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải lịch sử trò chuyện.',
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final repository = ref.read(aiAssistantRepositoryProvider);
    await repository.deleteConversation(conversationId);
    
    // Nếu cuộc hội thoại bị xóa trùng với cuộc hội thoại hiện tại, bắt đầu chat mới
    final currentChat = ref.read(aiChatProvider);
    if (currentChat.currentConversationId == conversationId) {
      ref.read(aiChatProvider.notifier).startNewChat();
    }
    await fetchConversations();
  }

  Future<void> renameConversation(String conversationId, String newTitle) async {
    final repository = ref.read(aiAssistantRepositoryProvider);
    await repository.renameConversation(conversationId, newTitle);
    
    // Cập nhật tiêu đề nếu là cuộc hội thoại hiện tại
    final currentChatNotifier = ref.read(aiChatProvider.notifier);
    final currentChat = ref.read(aiChatProvider);
    if (currentChat.currentConversationId == conversationId) {
      currentChatNotifier.state = currentChat.copyWith(
        conversationTitle: () => newTitle,
      );
    }
    await fetchConversations();
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
      final repository = ref.read(aiAssistantRepositoryProvider);
      final responseData = await repository.sendChatMessage(
        prompt: text,
        conversationId: state.currentConversationId,
      );

      final answer = responseData['answer'] ?? responseData['response'] ?? 'Không có phản hồi từ AI.';
      final insight = responseData['insight'];
      final List<String> suggestedQuestions = List<String>.from(responseData['suggested_questions'] ?? []);
      final newConversationId = responseData['conversation_id'] as String?;

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
      final repository = ref.read(aiAssistantRepositoryProvider);
      final responseData = await repository.getConversationMessages(conversationId);

      final conversationData = responseData['conversation'] as Map<String, dynamic>;
      final title = conversationData['title'] as String?;
      final rawMessages = responseData['messages'] as List;

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
