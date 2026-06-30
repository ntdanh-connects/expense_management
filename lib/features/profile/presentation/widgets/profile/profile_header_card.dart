import 'package:expense_management/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/shared/widgets/image_overlay_viewer.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String fullName;
  final String membershipTier;
  final String? avatarUrl;

  const ProfileHeaderCard({
    super.key,
    required this.fullName,
    required this.membershipTier,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      height: 235,
      decoration: BoxDecoration(
        gradient: colors.profileHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? () => ImageOverlayViewer.show(
                        context,
                        imageUrl: avatarUrl,
                        heroTag: 'avatar_profile',
                      )
                  : null,
              child: Hero(
                tag: 'avatar_profile',
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white24,
                    backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl!)
                        : null,
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? null
                        : const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            membershipTier,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    ),
  );
}
}
