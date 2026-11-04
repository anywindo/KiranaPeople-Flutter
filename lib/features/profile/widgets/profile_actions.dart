import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dialogs/logout_confirm_dialog.dart';
import 'sheets/edit_phone_sheet.dart';
import 'sheets/photo_source_sheet.dart';

export 'dialogs/logout_confirm_dialog.dart';
export 'dialogs/photo_confirm_dialog.dart';
export 'sheets/edit_phone_sheet.dart';
export 'sheets/photo_source_sheet.dart';

class ProfileActions {
  ProfileActions._();

  static void showCustomToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: isError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E222B).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  static void showPhotoSourceSheet(BuildContext context, WidgetRef ref) {
    PhotoSourceSheet.show(context, ref);
  }

  static void showEditPhoneBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String? currentPhone,
  ) {
    EditPhoneSheet.show(context, ref, currentPhone);
  }

  static void showLogoutDialog(BuildContext context, WidgetRef ref) {
    LogoutConfirmDialog.show(context, ref);
  }
}
