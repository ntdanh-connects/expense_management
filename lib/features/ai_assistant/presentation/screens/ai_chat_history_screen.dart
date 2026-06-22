import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/ai_assistant/presentation/providers/ai_chat_provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AIChatHistoryScreen extends ConsumerStatefulWidget {
  const AIChatHistoryScreen({super.key});

  @override
  ConsumerState<AIChatHistoryScreen> createState() => _AIChatHistoryScreenState();
}

class _AIChatHistoryScreenState extends ConsumerState<AIChatHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _loadingConversationId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Format date helper
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateToCheck == today) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateToCheck == yesterday) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(dateTime);
    }
  }

  // Chọn cuộc hội thoại để load
  Future<void> _onSelectConversation(BuildContext context, String conversationId) async {
    if (_loadingConversationId != null) return;

    setState(() {
      _loadingConversationId = conversationId;
    });

    try {
      await ref.read(aiChatProvider.notifier).loadConversation(conversationId);
      if (mounted) {
        Navigator.of(context).pop(true); // Trả về true báo hiệu đã chuyển cuộc hội thoại
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lịch sử: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingConversationId = null;
        });
      }
    }
  }

  // Xóa cuộc hội thoại
  Future<void> _onDeleteConversation(BuildContext context, AiConversation conversation) async {
    final colors = context.colors;
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.surface,
            title: const Text(
              'Xóa hội thoại',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa cuộc hội thoại "${conversation.title}"? Thao tác này không thể khôi phục.',
              style: TextStyle(color: colors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await ref
          .read(aiConversationsProvider.notifier)
          .deleteConversation(conversation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cuộc hội thoại thành công.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa cuộc hội thoại: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Đổi tên cuộc hội thoại
  Future<void> _onRenameConversation(BuildContext context, AiConversation conversation) async {
    final colors = context.colors;
    final renameController = TextEditingController(text: conversation.title);

    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.surface,
            title: const Text(
              'Đổi tên hội thoại',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              controller: renameController,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập tiêu đề cuộc hội thoại...',
                hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (renameController.text.trim().isEmpty) return;
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Lưu'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await ref
          .read(aiConversationsProvider.notifier)
          .renameConversation(conversation.id, renameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật tiêu đề cuộc hội thoại.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đổi tên: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsState = ref.watch(aiConversationsProvider);
    final activeChatState = ref.watch(aiChatProvider);

    // Lọc danh sách theo từ khóa tìm kiếm
    final filteredConversations = conversationsState.conversations.where((conv) {
      return conv.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: isDark ? colors.surface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Lịch sử trò chuyện AI',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_rounded, color: colors.primary),
            tooltip: 'Bắt đầu chat mới',
            onPressed: () {
              ref.read(aiChatProvider.notifier).startNewChat();
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔎 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? colors.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded, color: colors.textSecondary.withOpacity(0.6), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm cuộc hội thoại...',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withOpacity(0.5),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear_rounded, color: colors.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // 💬 Danh sách các cuộc trò chuyện
          Expanded(
            child: conversationsState.isLoading && conversationsState.conversations.isEmpty
                ? _buildShimmerLoading(isDark, colors)
                : conversationsState.errorMessage != null
                    ? _buildErrorWidget(conversationsState.errorMessage!, colors)
                    : filteredConversations.isEmpty
                        ? _buildEmptyState(colors, isDark)
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(aiConversationsProvider.notifier)
                                .fetchConversations(),
                            color: colors.primary,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredConversations.length,
                              itemBuilder: (context, index) {
                                final conv = filteredConversations[index];
                                final isSelected =
                                    activeChatState.currentConversationId == conv.id;
                                final isLoadingThis = _loadingConversationId == conv.id;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Dismissible(
                                    key: Key(conv.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    confirmDismiss: (dir) async {
                                      _onDeleteConversation(context, conv);
                                      return false; // Quản lý xóa bằng callback để có Dialog xác nhận
                                    },
                                    child: InkWell(
                                      onTap: () => _onSelectConversation(context, conv.id),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colors.primary.withOpacity(isDark ? 0.15 : 0.06)
                                              : (isDark ? colors.surface : Colors.white),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? colors.primary.withOpacity(0.4)
                                                : colors.textSecondary.withOpacity(0.08),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(isDark ? 0.03 : 0.01),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Icon Chat/Hội thoại
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? colors.primary.withOpacity(0.15)
                                                    : colors.textSecondary.withOpacity(0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.chat_bubble_outline_rounded,
                                                  color: isSelected ? colors.primary : colors.textSecondary,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),

                                            // Thông tin Text
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    conv.title,
                                                    style: TextStyle(
                                                      color: colors.textPrimary,
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatDateTime(conv.updatedAt),
                                                    style: TextStyle(
                                                      color: colors.textSecondary.withOpacity(0.7),
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Loading hoặc Action Button
                                            if (isLoadingThis)
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                                                ),
                                              )
                                            else
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  Icons.more_vert_rounded,
                                                  color: colors.textSecondary.withOpacity(0.8),
                                                  size: 20,
                                                ),
                                                onSelected: (val) {
                                                  if (val == 'rename') {
                                                    _onRenameConversation(context, conv);
                                                  } else if (val == 'delete') {
                                                    _onDeleteConversation(context, conv);
                                                  }
                                                },
                                                color: colors.surface,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 'rename',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, color: colors.textPrimary, size: 18),
                                                        const SizedBox(width: 8),
                                                        const Text('Đổi tên'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                        const SizedBox(width: 8),
                                                        Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark, dynamic colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message, dynamic colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(aiConversationsProvider.notifier).fetchConversations(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(dynamic colors, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: colors.primary.withOpacity(0.6),
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Không tìm thấy lịch sử chat',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Không tìm thấy cuộc hội thoại nào khớp với từ khóa tìm kiếm.'
                  : 'Hãy bắt đầu đặt câu hỏi cho EM AI Assistant để lưu trữ lịch sử trò chuyện của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary.withOpacity(0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(aiChatProvider.notifier).startNewChat();
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Bắt đầu hội thoại mới'),
              ),
          ],
        ),
      ),
    );
  }
}
