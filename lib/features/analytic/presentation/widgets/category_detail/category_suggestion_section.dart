import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/router/app_route.dart';

class CategorySuggestionSection extends StatelessWidget {
  final String categoryName;

  const CategorySuggestionSection({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final suggestions = [
      (
        icon: '👀',
        text: 'So sánh chi tiêu $categoryName với người 20 tuổi',
        query: 'Hãy so sánh mức chi tiêu cho danh mục $categoryName của tôi với mức trung bình của những người ở độ tuổi 20.',
      ),
      (
        icon: '✨',
        text: '20 tuổi, chi tiêu $categoryName như nào?',
        query: 'Ở tuổi 20, tôi nên chi tiêu cho danh mục $categoryName như thế nào cho hợp lý và tiết kiệm nhất?',
      ),
      (
        icon: '💡',
        text: 'Mẹo cắt giảm $categoryName hiệu quả',
        query: 'Hãy cho tôi một số mẹo thực tế để cắt giảm chi tiêu trong danh mục $categoryName.',
      ),
      (
        icon: '📊',
        text: 'Dự báo $categoryName tháng tới',
        query: 'Dựa trên lịch sử giao dịch của tôi, hãy dự báo chi tiêu danh mục $categoryName trong tháng tới và đưa ra lời khuyên.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Gợi ý cho bạn',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final suggestion = suggestions[index - 1];

              final List<Color> bgColorsLight = [
                const Color(0xFFE3F2FD),
                const Color(0xFFF3E5F5),
                const Color(0xFFE8F5E9),
                const Color(0xFFFFF3E0),
              ];
              final List<Color> borderColorsLight = [
                const Color(0xFFBBDEFB),
                const Color(0xFFE1BEE7),
                const Color(0xFFC8E6C9),
                const Color(0xFFFFE0B2),
              ];

              final chipIndex = (index - 1) % bgColorsLight.length;
              final bgColor = isDark ? colors.surface : bgColorsLight[chipIndex];
              final borderColor = isDark ? colors.textSecondary.withOpacity(0.15) : borderColorsLight[chipIndex];

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: ActionChip(
                    onPressed: () {
                      context.push(
                        RoutePaths.aiAssistant,
                        extra: suggestion.query,
                      );
                    },
                    avatar: Text(
                      suggestion.icon,
                      style: const TextStyle(fontSize: 13),
                    ),
                    label: Text(
                      suggestion.text,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: bgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: borderColor, width: 0.8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
