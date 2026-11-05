import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/connectivity_provider.dart';

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
      if (previous == true && next == false) {
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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
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
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Koneksi Internet Terputus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message ?? 'Perangkat Anda sedang offline. Presensi & sinkronisasi data memerlukan koneksi internet aktif.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF7F1D1D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: const Color(0xFF991B1B),
              onPressed: onRetry,
              tooltip: 'Periksa ulang',
            ),
        ],
      ),
    );
  }
}
