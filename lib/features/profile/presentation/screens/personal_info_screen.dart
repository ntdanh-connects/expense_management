import 'dart:io';

import 'package:dio/dio.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    
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
      await ref.read(updateProfileUseCaseProvider).execute(fullName: fullName);
      
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
                        backgroundImage: displayAvatar != null ? NetworkImage(displayAvatar) : null,
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
}