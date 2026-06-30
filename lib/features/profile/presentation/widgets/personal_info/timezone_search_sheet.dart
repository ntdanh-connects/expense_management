import 'package:flutter/material.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class TimezoneSearchSheet extends StatefulWidget {
  final List<String> timezones;
  final String? initialValue;
  final ValueChanged<String> onSelected;

  const TimezoneSearchSheet({
    super.key,
    required this.timezones,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<TimezoneSearchSheet> createState() => _TimezoneSearchSheetState();
}

class _TimezoneSearchSheetState extends State<TimezoneSearchSheet> {
  late List<String> _filteredTimezones;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredTimezones = widget.timezones;
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredTimezones = widget.timezones;
      } else {
        _filteredTimezones = widget.timezones
            .where((tz) => tz.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn Múi Giờ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm múi giờ...',
                hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.6)),
                border: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: colors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredTimezones.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy múi giờ nào',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredTimezones.length,
                    itemBuilder: (context, index) {
                      final tz = _filteredTimezones[index];
                      final isSelected = tz == widget.initialValue;

                      return ListTile(
                        title: Text(
                          tz,
                          style: TextStyle(
                            color: isSelected ? colors.primary : colors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: colors.primary)
                            : null,
                        onTap: () {
                          widget.onSelected(tz);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
