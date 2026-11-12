import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/user_model.dart';
import 'services/attendance_pdf_service.dart';

class AttendancePdfPreviewScreen extends StatelessWidget {
  final UserModel user;
  final List<AttendanceRecord> records;
  final String? periodLabel;

  const AttendancePdfPreviewScreen({
    super.key,
    required this.user,
    required this.records,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final sanitizedName = user.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final dateSuffix = DateTime.now().toIso8601String().substring(0, 10);
    final filename = 'rekap_presensi_${sanitizedName}_$dateSuffix.pdf';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Rekap Presensi PDF',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
      ),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (format) => AttendancePdfService.generateAttendanceReport(
          user: user,
          records: records,
          filterPeriodLabel: periodLabel,
          pageFormat: format,
        ),
        pdfFileName: filename,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pratinjau PDF Belum Siap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Modul native rendering (printing) memerlukan kompilasi ulang. Silakan hentikan (stop) sesi aplikasi dan jalankan ulang penuh (Full Rebuild / flutter run).\n\nHot Reload / Hot Restart tidak memuat plugin native baru ke dalam proses aplikasi yang sedang berjalan.',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Kembali ke Riwayat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

