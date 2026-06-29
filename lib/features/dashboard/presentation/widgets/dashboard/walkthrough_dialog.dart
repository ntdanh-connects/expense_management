import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class WalkthroughDialogContent extends ConsumerStatefulWidget {
  final AppColorsExtension colors;
  final bool isDark;

  const WalkthroughDialogContent({
    super.key,
    required this.colors,
    required this.isDark,
  });

  @override
  ConsumerState<WalkthroughDialogContent> createState() =>
      _WalkthroughDialogContentState();
}

class _WalkthroughDialogContentState
    extends ConsumerState<WalkthroughDialogContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDark = widget.isDark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 340,
        height: 480,
        decoration: BoxDecoration(
          color: isDark
              ? colors.surface.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : colors.primary.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildSlide(
                      icon: Icons.rocket_launch_rounded,
                      iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
                      title: 'walkthrough_welcome_title'.tr(ref),
                      description: 'walkthrough_welcome_desc'.tr(ref),
                    ),
                    _buildSlide(
                      icon: Icons.account_balance_wallet_rounded,
                      iconGradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      title: 'walkthrough_wallet_title'.tr(ref),
                      description: 'walkthrough_wallet_desc'.tr(ref),
                    ),
                    _buildSlide(
                      icon: Icons.autorenew_rounded,
                      iconGradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
                      title: 'walkthrough_recurring_title'.tr(ref),
                      description: 'walkthrough_recurring_desc'.tr(ref),
                    ),
                    _buildSlide(
                      icon: Icons.pie_chart_rounded,
                      iconGradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                      title: 'walkthrough_budget_title'.tr(ref),
                      description: 'walkthrough_budget_desc'.tr(ref),
                    ),
                  ],
                ),
              ),
              // Dots and actions row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip button
                    Opacity(
                      opacity: _currentPage == 3 ? 0.0 : 1.0,
                      child: TextButton(
                        onPressed: _currentPage == 3
                            ? null
                            : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                        ),
                        child: Text(
                          'walkthrough_skip'.tr(ref),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    // Dots indicator
                    Row(
                      children: List.generate(4, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? colors.primary
                                : colors.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    // Next / Finish button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 3) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        _currentPage == 3
                            ? 'walkthrough_finish'.tr(ref)
                            : 'walkthrough_next'.tr(ref),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  Widget _buildSlide({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String description,
  }) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon visual
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconGradient.first.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
