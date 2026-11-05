import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/user_model.dart';
import '../../attendance/widgets/photo_preview_dialog.dart';

Widget _buildInitialAvatar(String name, {double fontSize = 28}) {
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
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
}

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

class ProfileHeaderBanner extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onAvatarEditTap;

  const ProfileHeaderBanner({
    super.key,
    required this.user,
    required this.onAvatarEditTap,
  });

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
                      color: AppColors.primary,
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
                      onTap: () =>
                          _showEnlargedPhotoDialog(context, user, userName),
                      child: Container(
                        width: avatarDiameter,
                        height: avatarDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.isDarkMode
                                ? const Color(0xFF334155)
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
                                        child: SkeletonBox.circle(size: 88),
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
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.isDarkMode
                                  ? context.scaffoldBg
                                  : Colors.white,
                              width: 2.5,
                            ),
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

/// Sticky SliverPersistentHeader delegate that seamlessly shrinks into
/// a compact smaller profile section pinned at the top when user scrolls down.
class ProfileStickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UserModel? user;
  final VoidCallback onAvatarEditTap;
  final double topPadding;

  const ProfileStickyHeaderDelegate({
    required this.user,
    required this.onAvatarEditTap,
    required this.topPadding,
  });

  @override
  double get minExtent => topPadding + 60.0;

  @override
  double get maxExtent {
    final bannerHeight = 125.0 + topPadding;
    const avatarDiameter = 96.0;
    const avatarHalf = avatarDiameter / 2; // 48.0
    return bannerHeight + avatarHalf + 68.0;
  }

  @override
  bool shouldRebuild(covariant ProfileStickyHeaderDelegate oldDelegate) {
    return oldDelegate.user != user ||
        oldDelegate.onAvatarEditTap != onAvatarEditTap ||
        oldDelegate.topPadding != topPadding;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = context.isDarkMode;
    final userName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user!.name.trim()
        : (user?.employeeId ?? '-');
    final username =
        (user?.employeeId != null && user!.employeeId!.trim().isNotEmpty)
        ? user!.employeeId!.trim()
        : '';
    final userHandle = username;

    final bannerHeight = 125.0 + topPadding;
    const avatarDiameter = 96.0;
    const avatarHalf = avatarDiameter / 2; // 48.0

    final maxScroll = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (shrinkOffset / maxScroll).clamp(0.0, 1.0);

    // Opacity transitions
    final expandedOpacity = (1.0 - t * 1.5).clamp(0.0, 1.0);
    final stickyBarOpacity = ((t - 0.20) / 0.50).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.45) / 0.45).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t >= 0.5
            ? (isDark ? Brightness.light : Brightness.dark)
            : Brightness.light,
        statusBarBrightness: t >= 0.5
            ? (isDark ? Brightness.dark : Brightness.light)
            : Brightness.dark,
      ),
      child: ClipRect(
        child: Container(
          color: context.scaffoldBg,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              // 1. EXPANDED SECTION (Banner + Big Avatar + Big Title)
              if (expandedOpacity > 0.0) ...[
                // Parallax Banner Image
                Positioned(
                  top: -shrinkOffset * 0.4,
                  left: 0,
                  right: 0,
                  height: bannerHeight,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: Image.asset(
                      'assets/images/header-bar.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppColors.primary),
                    ),
                  ),
                ),

                // Large Avatar (96px) + Camera Button
                Positioned(
                  left: 20,
                  top: bannerHeight - avatarHalf - shrinkOffset,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _showEnlargedPhotoDialog(context, user, userName),
                          child: Container(
                            width: avatarDiameter,
                            height: avatarDiameter,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
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
                                            child: SkeletonBox.circle(size: 88),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          _buildInitialAvatar(userName),
                                    )
                                  : _buildInitialAvatar(userName),
                            ),
                          ),
                        ),
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
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? context.scaffoldBg
                                      : Colors.white,
                                  width: 2.5,
                                ),
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
                ),

                // Big User Name & Handle below Avatar
                Positioned(
                  left: 20,
                  right: 20,
                  top: bannerHeight + avatarHalf + 10.0 - shrinkOffset,
                  child: Opacity(
                    opacity: expandedOpacity,
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
                ),
              ],

              // 2. STICKY TOP BAR SURFACE (Solid Surface with Dual Shadow & Contour Border)
              if (stickyBarOpacity > 0.0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: minExtent,
                  child: Opacity(
                    opacity: stickyBarOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.08,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.20 : 0.04,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. COMPACT SMALLER PROFILE SECTION (Small Avatar + Name + Handle)
              if (compactOpacity > 0.0)
                Positioned(
                  top: topPadding,
                  left: 16,
                  right: 16,
                  height: 60.0,
                  child: Opacity(
                    opacity: compactOpacity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Small circular avatar (38px)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _showEnlargedPhotoDialog(context, user, userName),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
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
                                            child: SkeletonBox.circle(size: 38),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          _buildInitialAvatar(
                                            userName,
                                            fontSize: 14,
                                          ),
                                    )
                                  : _buildInitialAvatar(
                                      userName,
                                      fontSize: 14,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name & Handle in compact row
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                              if (userHandle.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  userHandle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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
