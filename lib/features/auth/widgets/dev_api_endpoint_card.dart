import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../providers/connectivity_provider.dart';

class DevApiEndpointCard extends ConsumerStatefulWidget {
  final bool forceVisible;

  const DevApiEndpointCard({
    super.key,
    this.forceVisible = false,
  });

  @override
  ConsumerState<DevApiEndpointCard> createState() => _DevApiEndpointCardState();
}

class _DevApiEndpointCardState extends ConsumerState<DevApiEndpointCard> {
  late final TextEditingController _controller;
  bool _isExpanded = false;
  bool _isLoading = true;
  String _currentSavedUrl = ApiConfig.defaultBaseUrl;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadCurrentEndpoint();
  }

  Future<void> _loadCurrentEndpoint() async {
    final currentUrl = await ApiConfig.getBaseUrl();
    if (mounted) {
      setState(() {
        _currentSavedUrl = currentUrl;
        _controller.text = currentUrl;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEndpoint([String? customUrl]) async {
    final targetUrl = (customUrl ?? _controller.text).trim();
    if (targetUrl.isEmpty) {
      await _resetEndpoint();
      return;
    }

    AppHaptics.success();
    await ApiConfig.setBaseUrl(targetUrl);
    try {
      ref.read(isOfflineProvider.notifier).checkConnection(force: true);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _currentSavedUrl = targetUrl;
        _controller.text = targetUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Endpoint API disimpan: $targetUrl'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetEndpoint() async {
    AppHaptics.light();
    await ApiConfig.resetBaseUrl();
    try {
      ref.read(isOfflineProvider.notifier).checkConnection(force: true);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _currentSavedUrl = ApiConfig.defaultBaseUrl;
        _controller.text = ApiConfig.defaultBaseUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endpoint API dikembalikan ke default.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode && !widget.forceVisible) {
      return const SizedBox.shrink();
    }

    final isDark = context.isDarkMode;
    final isCustom = _currentSavedUrl != ApiConfig.defaultBaseUrl;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCustom
              ? const Color(0xFFF59E0B)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A)),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Toggle
          InkWell(
            onTap: () {
              AppHaptics.light();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Dev: API Endpoint',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCustom
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCustom ? 'CUSTOM' : 'DEFAULT',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: isCustom
                                      ? Colors.white
                                      : context.textMutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading ? 'Memuat...' : _currentSavedUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.textMutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.textMutedColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Body
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Atur base URL endpoint backend untuk kebutuhan pengujian:',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input Field
                  TextField(
                    controller: _controller,
                    cursorColor: AppColors.primary,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'https://kp.krtekstile.com/api/v1',
                      prefixIcon: const Icon(Icons.dns_outlined, size: 18),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Quick Presets
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildPresetChip(
                        label: 'Production Default',
                        url: ApiConfig.defaultBaseUrl,
                      ),
                      _buildPresetChip(
                        label: 'Android Emul (10.0.2.2:8000)',
                        url: 'http://10.0.2.2:8000/api/v1',
                      ),
                      _buildPresetChip(
                        label: 'Localhost (127.0.0.1:8000)',
                        url: 'http://127.0.0.1:8000/api/v1',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetEndpoint,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            'Reset Default',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _saveEndpoint(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required String url,
  }) {
    final isSelected = _controller.text.trim() == url;
    return InkWell(
      onTap: () {
        AppHaptics.selection();
        setState(() {
          _controller.text = url;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }
}
