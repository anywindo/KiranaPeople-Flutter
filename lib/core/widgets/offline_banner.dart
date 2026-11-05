import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connectivity_provider.dart';
import '../utils/app_haptics.dart';

class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _showReconnectedBanner = false;
  Timer? _reconnectedTimer;
  bool _isChecking = false;

  @override
  void dispose() {
    _reconnectedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);

    // Listen for reconnection to briefly show the green reconnected banner
    ref.listen<bool>(isOfflineProvider, (previous, next) {
      if (previous == false && next == true) {
        AppHaptics.error();
      } else if (previous == true && next == false) {
        AppHaptics.selection();
        setState(() {
          _showReconnectedBanner = true;
        });
        _reconnectedTimer?.cancel();
        _reconnectedTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showReconnectedBanner = false;
            });
          }
        });
      }
    });

    final isVisible = isOffline || _showReconnectedBanner;

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      crossFadeState: isVisible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isOffline ? const Color(0xFFDC2626) : const Color(0xFF059669),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isOffline
                            ? 'Mode Offline (Tidak Ada Internet)'
                            : 'Terhubung Kembali',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        isOffline
                            ? 'Periksa Wi-Fi atau kuota data seluler Anda.'
                            : 'Data presensi sedang disinkronisasi.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isOffline) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isChecking
                        ? null
                        : () async {
                            AppHaptics.light();
                            setState(() {
                              _isChecking = true;
                            });
                            await ref
                                .read(isOfflineProvider.notifier)
                                .checkConnection();
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            if (mounted) {
                              setState(() {
                                _isChecking = false;
                              });
                            }
                          },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      secondChild: const SizedBox(width: double.infinity, height: 0),
    );
  }
}

/// Standalone offline card alert that can be embedded directly in screens
class OfflineCardWarning extends ConsumerWidget {
  final String? message;
  final VoidCallback? onRetry;

  const OfflineCardWarning({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    if (!isOffline) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2D1214) : const Color(0xFFFEF2F2);
    final borderColor =
        isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5);
    final iconBg =
        isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
    final iconColor =
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
    final titleColor =
        isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B);
    final textColor =
        isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koneksi Internet Terputus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message ??
                      'Perangkat Anda sedang offline. Presensi & sinkronisasi data memerlukan koneksi internet aktif.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: titleColor,
              onPressed: () {
                AppHaptics.light();
                onRetry!();
              },
              tooltip: 'Periksa ulang',
            ),
        ],
      ),
    );
  }
}
