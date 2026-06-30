import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';

class PersonalInfoAvatar extends ConsumerStatefulWidget {
  final String? initialAvatarUrl;

  const PersonalInfoAvatar({
    super.key,
    required this.initialAvatarUrl,
  });

  @override
  ConsumerState<PersonalInfoAvatar> createState() => _PersonalInfoAvatarState();
}

class _PersonalInfoAvatarState extends ConsumerState<PersonalInfoAvatar> {
  bool _isUploadingAvatar = false;
  final ImagePicker _picker = ImagePicker();
  String? _localAvatarUrl;

  @override
  void initState() {
    super.initState();
    _localAvatarUrl = widget.initialAvatarUrl;
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(currentUserProvider);
    final displayAvatar = currentUser?.avatarUrl ?? _localAvatarUrl;

    return Center(
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
              backgroundImage: displayAvatar != null && displayAvatar.isNotEmpty 
                  ? CachedNetworkImageProvider(displayAvatar) 
                  : null,
              child: displayAvatar == null || displayAvatar.isEmpty
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
    );
  }
}
