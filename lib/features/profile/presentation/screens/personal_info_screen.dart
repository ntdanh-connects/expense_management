import 'dart:io';

import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCurrency;
  String? _selectedTimezone;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedCurrency = user?.currency ?? 'VND';
    _selectedTimezone = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
       _avatarUrl = user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      File imageFile = File(image.path);

      await ref.read(updateAvatarUseCaseProvider).execute(imageFile: imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_avatar_success'.tr(ref)),
            backgroundColor: context.colors.incomeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('upload_avatar_error'.tr(ref) + e.toString()),
            backgroundColor: context.colors.expenseRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) return;

    setState(() => _isSaving = true);
    
    try {
      // GỌI API UPDATE PROFILE
      await ref.read(updateProfileUseCaseProvider).execute(
        fullName: fullName,
        currency: _selectedCurrency,
        timezone: _selectedTimezone,
      );
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_profile_success'.tr(ref)), 
            backgroundColor: context.colors.incomeGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_profile_error'.tr(ref) + e.toString()), 
            backgroundColor: context.colors.expenseRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: colors.surface,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: readOnly ? colors.surface.withOpacity(0.5) : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: readOnly ? colors.textSecondary.withOpacity(0.5) : colors.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: readOnly ? colors.textSecondary.withOpacity(0.5) : colors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  validator: validator,
                  style: TextStyle(
                    color: readOnly ? colors.textSecondary : colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final optionsAsync = ref.watch(preferenceOptionsProvider);

    final currentUser = ref.watch(currentUserProvider);
    final displayAvatar = currentUser?.avatarUrl ?? _avatarUrl;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'edit_profile'.tr(ref),
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // AVATAR
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primary.withOpacity(0.5), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 65, 
                        backgroundColor: colors.primary.withOpacity(0.1),
                        backgroundImage: displayAvatar != null ? CachedNetworkImageProvider(displayAvatar) : null,
                        child: displayAvatar == null 
                            ? Icon(Icons.person_rounded, size: 70, color: colors.primary) 
                            : null,
                      ),
                    ),

                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),

                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _pickAvatarFromGallery,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.surface, width: 2.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // NHẬP HỌ TÊN
              _buildInputField(
                label: 'full_name_label'.tr(ref),
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'please_enter_name'.tr(ref) : null,
              ),
              
              // EMAIL KHÓA
              _buildInputField(
                label: 'email_label'.tr(ref),
                icon: Icons.email_outlined,
                controller: _emailController,
                readOnly: true,
              ),

              // CHỌN TIỀN TỆ MẶC ĐỊNH & MÚI GIỜ (Tải động từ Server)
              optionsAsync.when(
                data: (options) {
                  // Fallback an toàn nếu giá trị hiện tại của user không nằm trong list options mới tải từ server
                  final availableCurrencies = options.currencies.map((c) => c.code).toList();
                  if (_selectedCurrency == null || !availableCurrencies.contains(_selectedCurrency)) {
                    _selectedCurrency = availableCurrencies.isNotEmpty ? availableCurrencies.first : 'VND';
                  }

                  final availableTimezones = options.timezones;
                  if (_selectedTimezone == null || !availableTimezones.contains(_selectedTimezone)) {
                    _selectedTimezone = availableTimezones.contains('Asia/Ho_Chi_Minh') 
                        ? 'Asia/Ho_Chi_Minh' 
                        : (availableTimezones.isNotEmpty ? availableTimezones.first : 'Asia/Ho_Chi_Minh');
                  }

                  // Danh sách múi giờ phổ biến/nổi bật để tránh bị loãng UI
                  final popularTimezones = const [
                    'Asia/Ho_Chi_Minh',
                    'Asia/Singapore',
                    'Asia/Bangkok',
                    'Asia/Tokyo',
                    'Asia/Seoul',
                    'Asia/Shanghai',
                    'Asia/Hong_Kong',
                    'Asia/Jakarta',
                    'Europe/London',
                    'Europe/Paris',
                    'America/New_York',
                    'America/Los_Angeles',
                    'Australia/Sydney',
                  ];

                  // Lọc danh sách: chỉ hiện múi giờ phổ biến và luôn giữ lại múi giờ hiện tại của user để tránh bị lỗi
                  final filteredTimezones = availableTimezones.where((tz) {
                    return popularTimezones.contains(tz) || tz == _selectedTimezone;
                  }).toList();

                  return Column(
                    children: [
                      // Chọn Múi giờ với Searchable Bottom Sheet
                      GestureDetector(
                        onTap: () => _showTimezoneSearchSheet(context, filteredTimezones),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.public_rounded, color: colors.textSecondary, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'timezone_label'.tr(ref),
                                      style: TextStyle(
                                        color: colors.textSecondary.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedTimezone!,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                color: colors.textSecondary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
                  final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

                  Widget buildShimmerItem() {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 80,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 150,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }

                  return Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Column(
                      children: [
                        buildShimmerItem(),
                        buildShimmerItem(),
                      ],
                    ),
                  );
                },
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.expenseRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Lỗi tải cấu hình: $err',
                    style: TextStyle(color: colors.expenseRed),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),

              // NÚT LƯU
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
                        )
                      : Text(
                          'save_changes'.tr(ref),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimezoneSearchSheet(BuildContext context, List<String> timezones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TimezoneSearchSheet(
          timezones: timezones,
          initialValue: _selectedTimezone,
          onSelected: (tz) {
            setState(() {
              _selectedTimezone = tz;
            });
          },
        );
      },
    );
  }
}

class _TimezoneSearchSheet extends StatefulWidget {
  final List<String> timezones;
  final String? initialValue;
  final ValueChanged<String> onSelected;

  const _TimezoneSearchSheet({
    required this.timezones,
    required this.initialValue,
    required this.onSelected,
  });

  @override
  State<_TimezoneSearchSheet> createState() => _TimezoneSearchSheetState();
}

class _TimezoneSearchSheetState extends State<_TimezoneSearchSheet> {
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
          // Thanh kéo ngang nhỏ phía trên sheet
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
          // Hộp tìm kiếm
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
          // Danh sách múi giờ
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