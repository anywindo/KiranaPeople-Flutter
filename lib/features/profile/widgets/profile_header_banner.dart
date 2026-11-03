import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/user_model.dart';
import '../../attendance/widgets/photo_preview_dialog.dart';

class ProfileHeaderBanner extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onAvatarEditTap;

  const ProfileHeaderBanner({
    super.key,
    required this.user,
    required this.onAvatarEditTap,
  });

  void _showEnlargedPhotoDialog(
    BuildContext context,
    UserModel? user,
    String userName,
  ) {
    final avatarUrl = user?.fullAvatarUrl;
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return;

    PhotoPreviewDialog.show(
      context,
      imageUrl: avatarUrl,
      title: userName,
      subtitle: 'Foto Profil',
      customFileName: 'profile_${user?.employeeId ?? "user"}.jpg',
    );
  }

  Widget _buildInitialAvatar(String name) {
    String initials = 'UT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return Container(
      color: const Color(0xFF4F46E5),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user!.name.trim()
        : (user?.employeeId ?? '-');
    final username =
        (user?.employeeId != null && user!.employeeId!.trim().isNotEmpty)
            ? user!.employeeId!.trim()
            : '';
    final userHandle = username;

    final topPadding = MediaQuery.of(context).padding.top;
    final bannerHeight = 125.0 + topPadding;
    const avatarDiameter = 96.0;
    const avatarHalf = avatarDiameter / 2; // 48.0
    final headerTotalHeight = bannerHeight + avatarHalf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: headerTotalHeight,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner Image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: bannerHeight,
                child: Image.asset(
                  'assets/images/header-bar.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFF21A4),
                            Color(0xFF7C3AED),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Avatar overlapping the banner bottom (Left aligned)
              Positioned(
                left: 20,
                top: bannerHeight - avatarHalf,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomRight,
                  children: [
                    // 1. Tapping avatar enlarges the photo
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showEnlargedPhotoDialog(
                        context,
                        user,
                        userName,
                      ),
                      child: Container(
                        width: avatarDiameter,
                        height: avatarDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.isDarkMode
                                ? context.scaffoldBg
                                : Colors.white,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              (user?.fullAvatarUrl != null &&
                                      user!.fullAvatarUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: user!.fullAvatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const ShimmerLoading(
                                        child: SkeletonBox.circle(
                                          size: 88,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          _buildInitialAvatar(userName),
                                    )
                                  : _buildInitialAvatar(userName),
                        ),
                      ),
                    ),

                    // 2. Tapping camera badge opens photo source modal
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onAvatarEditTap,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2D75),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.isDarkMode
                                  ? context.scaffoldBg
                                  : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Clearance for overlapping avatar
        const SizedBox(height: 12),

        // User Name & Handle (Left aligned as per reference)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (userHandle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  userHandle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

