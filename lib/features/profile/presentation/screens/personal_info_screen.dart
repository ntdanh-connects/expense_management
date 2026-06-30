import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/personal_info/personal_info_avatar.dart';
import '../widgets/personal_info/personal_info_input_field.dart';
import '../widgets/personal_info/timezone_search_sheet.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  bool _isSaving = false;
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) return;

    setState(() => _isSaving = true);
    
    try {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final optionsAsync = ref.watch(preferenceOptionsProvider);
    final currentUser = ref.watch(currentUserProvider);

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
              PersonalInfoAvatar(
                initialAvatarUrl: currentUser?.avatarUrl,
              ),
              const SizedBox(height: 48),

              // NHẬP HỌ TÊN
              PersonalInfoInputField(
                label: 'full_name_label'.tr(ref),
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'please_enter_name'.tr(ref) : null,
              ),
              
              // EMAIL KHÓA
              PersonalInfoInputField(
                label: 'email_label'.tr(ref),
                icon: Icons.email_outlined,
                controller: _emailController,
                readOnly: true,
              ),

              // CHỌN TIỀN TỆ MẶC ĐỊNH & MÚI GIỜ
              optionsAsync.when(
                data: (options) {
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
        return TimezoneSearchSheet(
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