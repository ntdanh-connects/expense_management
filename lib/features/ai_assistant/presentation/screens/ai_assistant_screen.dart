import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/ai_chat_provider.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const AIAssistantScreen({super.key, this.initialMessage});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage);
      });
    }
  }
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Tháng này tôi tiêu nhiều nhất khoản gì? ✨',
    'Tóm tắt chi tiêu tuần này',
    'Gợi ý cắt giảm chi tiêu tháng này',
    'Tôi muốn tiết kiệm 5 triệu trong 3 tháng',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? text]) {
    final messageText = text ?? _messageController.text;
    if (messageText.trim().isEmpty) return;

    ref.read(aiChatProvider.notifier).sendMessage(messageText);
    if (text == null) {
      _messageController.clear();
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chatState = ref.watch(aiChatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    // Auto-scroll when new messages arrive or loading state changes
    ref.listen(aiChatProvider, (previous, next) {
      _scrollToBottom();
    });

    // Lấy câu hỏi gợi ý từ tin nhắn cuối cùng của AI (nếu có)
    final lastAiMessage = chatState.messages.isNotEmpty
        ? chatState.messages.lastWhere((m) => !m.isUser, orElse: () => chatState.messages.first)
        : null;
    final List<String> displaySuggestions = (lastAiMessage != null && lastAiMessage.suggestedQuestions.isNotEmpty)
        ? lastAiMessage.suggestedQuestions
        : _suggestions;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: isDark ? colors.surface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          chatState.conversationTitle ?? 'EM AI Assistant',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chatState.conversationTitle != null ? 'EM AI Assistant' : 'Active now',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: colors.textPrimary),
            tooltip: 'Lịch sử trò chuyện',
            onPressed: () async {
              final changed = await context.push<bool>('/ai-assistant/history');
              if (changed == true) {
                _scrollToBottom();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: colors.textPrimary),
            onPressed: () {
              // Action sheet để xóa hội thoại
              showModalBottomSheet(
                context: context,
                backgroundColor: colors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.chat_bubble_outline_rounded, color: colors.primary),
                        title: Text('Cuộc trò chuyện mới', style: TextStyle(color: colors.textPrimary)),
                        onTap: () {
                          ref.read(aiChatProvider.notifier).startNewChat();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.history_rounded, color: colors.textPrimary),
                        title: Text('Lịch sử trò chuyện', style: TextStyle(color: colors.textPrimary)),
                        onTap: () async {
                          Navigator.pop(context);
                          final changed = await context.push<bool>('/ai-assistant/history');
                          if (changed == true) {
                            _scrollToBottom();
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        title: const Text('Reset cuộc hội thoại này', style: TextStyle(color: Colors.redAccent)),
                        onTap: () {
                          ref.read(aiChatProvider.notifier).clearChat();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 💬 1. KHU VỰC HIỂN THỊ TIN NHẮN
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có tin nhắn nào.',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chatState.messages.length) {
                          // Tin nhắn Loading
                          return _buildLoadingBubble(colors, isDark);
                        }

                        final message = chatState.messages[index];
                        return _buildMessageItem(message, colors, isDark, currentUser?.avatarUrl);
                      },
                    ),
            ),

            // 💡 2. GỢI Ý NHANH (SUGGESTION CHIPS)
            if (!chatState.isLoading)
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: displaySuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = displaySuggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        onPressed: () => _sendMessage(suggestion),
                        label: Text(
                          suggestion,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: isDark ? colors.surface : Colors.grey[100],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: colors.textSecondary.withOpacity(0.1)),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ✍️ 3. THANH NHẬP LIỆU CHAT
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? colors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.05 : 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: colors.textPrimary, fontSize: 14),
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: 'Hỏi EM về tài chính...',
                                hintStyle: TextStyle(
                                  color: colors.textSecondary.withOpacity(0.6),
                                  fontSize: 13.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onSubmitted: (val) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.mic_none_rounded, color: colors.textSecondary),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tính năng nhận diện giọng nói đang được phát triển!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF9C27B0), // Purple
                            Color(0xFFE91E63), // Pink
                            Color(0xFF00BCD4), // Cyan
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ⚠️ 4. Bottom Disclaimer
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4),
              child: Text(
                'EM AI CAN PROVIDE FINANCIAL INSIGHTS BUT NOT PROFESSIONAL ADVICE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary.withOpacity(0.5),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserLastName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'bạn';
    return fullName.trim().split(' ').last;
  }

  Widget _buildMessageItem(ChatMessage message, dynamic colors, bool isDark, String? userAvatarUrl) {
    if (message.isUser) {
      // Tin nhắn người dùng (Bên phải)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary.withOpacity(0.2),
              backgroundImage: userAvatarUrl != null ? NetworkImage(userAvatarUrl) : null,
              child: userAvatarUrl == null
                  ? Icon(Icons.person_rounded, color: colors.primary, size: 16)
                  : null,
            ),
          ],
        ),
      );
    } else {
      // Tin nhắn Bot (Bên trái)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9C27B0), // Purple
                    Color(0xFFE91E63), // Pink
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? colors.surface : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.03 : 0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (message.insight != null && message.insight!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2415) : const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF5C4E35) : const Color(0xFFFFE0B2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Colors.orangeAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.insight!,
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFFD180) : const Color(0xFFE65100),
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingBubble(dynamic colors, bool isDark) {
    final currentUser = ref.watch(currentUserProvider);
    final userName = _getUserLastName(currentUser?.fullName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9C27B0), // Purple
                  Color(0xFFE91E63), // Pink
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$userName chờ EM xíu nha',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
