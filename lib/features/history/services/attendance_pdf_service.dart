import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/date_formatter.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/user_model.dart';

class AttendancePdfService {
  AttendancePdfService._();

  // Formal Monochrome & Grayscale Palette
  static const PdfColor inkBlack = PdfColors.black;
  static const PdfColor textMuted = PdfColor.fromInt(0xFF475569);
  static const PdfColor tableHeaderBg = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor rowEvenBg = PdfColors.white;
  static const PdfColor rowOddBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor lineBorder = PdfColor.fromInt(0xFFCBD5E1);

  /// Generate attendance report PDF as bytes (A4 format).
  static Future<Uint8List> generateAttendanceReport({
    required UserModel user,
    required List<AttendanceRecord> records,
    String? filterPeriodLabel,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document(
      title: 'Rekap Presensi - ${user.name}',
      author: 'Kirana Group',
    );

    // Load logo Kirana if not provided
    Uint8List? effectiveLogoBytes = logoBytes;
    if (effectiveLogoBytes == null) {
      try {
        final byteData =
            await rootBundle.load('assets/images/logoKiranaSquare.jpeg');
        effectiveLogoBytes = byteData.buffer.asUint8List();
      } catch (_) {
        // Graceful fallback in headless testing environments
      }
    }

    final pw.ImageProvider? logoImage = effectiveLogoBytes != null
        ? pw.MemoryImage(effectiveLogoBytes)
        : null;

    // Compute metrics
    final totalDays = records.length;
    final lateCount = records.where((r) => r.isLate).length;
    final onTimeCount = totalDays - lateCount;
    final onTimePercentage = totalDays > 0
        ? ((onTimeCount / totalDays) * 100).toStringAsFixed(1)
        : '0.0';

    final now = DateTime.now();
    final generatedAtStr =
        '${DateFormatter.formatFullDate(now)}, ${DateFormatter.formatTime(now)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        header: (context) =>
            _buildReportHeader(context, generatedAtStr, logoImage),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),

          // 1. Employee Info Card & KPI Metrics
          _buildEmployeeInfoAndKpis(
            user: user,
            periodLabel: filterPeriodLabel ?? 'Semua Riwayat Tercatat',
            totalDays: totalDays,
            onTimeCount: onTimeCount,
            lateCount: lateCount,
            onTimePercentage: onTimePercentage,
          ),
          pw.SizedBox(height: 16),

          // 2. Attendance Table
          _buildAttendanceTable(records),
          pw.SizedBox(height: 16),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildReportHeader(
    pw.Context context,
    String generatedAt,
    pw.ImageProvider? logoImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: inkBlack, width: 2.0),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  width: 38,
                  height: 38,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.ClipRRect(
                    horizontalRadius: 4,
                    verticalRadius: 4,
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  ),
                ),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'KIRANA GROUP',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: inkBlack,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Laporan Rekapitulasi Presensi Karyawan',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      color: textMuted,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Tanggal Cetak:',
                style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                '$generatedAt WIB',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: inkBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEmployeeInfoAndKpis({
    required UserModel user,
    required String periodLabel,
    required int totalDays,
    required int onTimeCount,
    required int lateCount,
    required String onTimePercentage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: rowOddBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: lineBorder, width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: Employee Profile
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  user.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12.5,
                    fontWeight: pw.FontWeight.bold,
                    color: inkBlack,
                  ),
                ),
                pw.SizedBox(height: 4),
                _buildInfoRow('ID Karyawan', user.employeeId ?? '-'),
                _buildInfoRow('NIK', user.nik ?? '-'),
                _buildInfoRow('Email', user.email),
                _buildInfoRow(
                  'Lokasi Kerja',
                  user.location?.name ?? 'Semua Lokasi',
                ),
                _buildInfoRow('Periode Rekap', periodLabel),
              ],
            ),
          ),
          pw.SizedBox(width: 14),
          // Right: KPI Summary Cards (Formal Monochrome)
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    _buildKpiCard('Total Hadir', '$totalDays'),
                    pw.SizedBox(width: 6),
                    _buildKpiCard('Ketepatan', '$onTimePercentage%'),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    _buildKpiCard('Tepat Waktu', '$onTimeCount'),
                    pw.SizedBox(width: 6),
                    _buildKpiCard('Terlambat', '$lateCount'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
            ),
          ),
          pw.Text(': ',
              style: const pw.TextStyle(fontSize: 8.5, color: textMuted)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: inkBlack,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiCard(String title, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: lineBorder, width: 0.7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: inkBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAttendanceTable(List<AttendanceRecord> records) {
    final headers = [
      'No',
      'Tanggal & Hari',
      'Shift',
      'Masuk',
      'Istirahat',
      'Pulang',
      'Status',
    ];

    if (records.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 20),
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: lineBorder, width: 0.5),
        ),
        child: pw.Text(
          'Tidak ada data presensi pada periode ini.',
          style: const pw.TextStyle(fontSize: 9, color: textMuted),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: lineBorder, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24), // No
        1: const pw.FlexColumnWidth(2.5), // Tanggal
        2: const pw.FlexColumnWidth(1.5), // Shift
        3: const pw.FlexColumnWidth(1.2), // Masuk
        4: const pw.FlexColumnWidth(1.8), // Istirahat
        5: const pw.FlexColumnWidth(1.2), // Pulang
        6: const pw.FlexColumnWidth(1.5), // Status
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: tableHeaderBg),
          children: headers.map((h) {
            return pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: inkBlack,
                ),
                textAlign: h == 'No' || h == 'Status'
                    ? pw.TextAlign.center
                    : pw.TextAlign.left,
              ),
            );
          }).toList(),
        ),

        // Table Data Rows
        ...records.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final r = entry.value;

          final dt = DateTime.tryParse(r.date);
          final dateStr =
              dt != null ? DateFormatter.formatFullDate(dt) : r.date;

          final checkInStr =
              _extractEventTime(r, AttendanceEventType.startShift);
          final breakStart =
              _extractEventTime(r, AttendanceEventType.startBreak);
          final breakEnd = _extractEventTime(r, AttendanceEventType.endBreak);
          final checkOutStr =
              _extractEventTime(r, AttendanceEventType.endShift);

          String breakStr = '-';
          if (breakStart != '-' && breakEnd != '-') {
            breakStr = '$breakStart - $breakEnd';
          } else if (breakStart != '-') {
            breakStr = '$breakStart - ...';
          }

          final isLate = r.isLate;
          final statusLabel = isLate ? 'Terlambat' : 'Tepat Waktu';
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? rowEvenBg : rowOddBg,
            ),
            children: [
              _buildCell('$index', align: pw.TextAlign.center),
              _buildCell(dateStr, isBold: true),
              _buildCell(r.shift?.name ?? 'Reguler'),
              _buildCell(checkInStr),
              _buildCell(breakStr),
              _buildCell(checkOutStr),
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: pw.BoxDecoration(
                      color: isLate ? tableHeaderBg : PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(3),
                      border: pw.Border.all(
                        color: isLate ? inkBlack : lineBorder,
                        width: 0.5,
                      ),
                    ),
                    child: pw.Text(
                      statusLabel,
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight:
                            isLate ? pw.FontWeight.bold : pw.FontWeight.normal,
                        color: inkBlack,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          color: inkBlack,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _extractEventTime(
      AttendanceRecord r, AttendanceEventType type) {
    for (final e in r.events) {
      if (e.eventType == type) {
        final dt = DateTime.tryParse(e.timestamp);
        if (dt != null) {
          final local = dt.isUtc ? dt.toLocal() : dt;
          return DateFormatter.formatTime(local);
        }
      }
    }
    return '-';
  }

  static pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: lineBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'KIRANA GROUP | Rekapitulasi Presensi Karyawan',
            style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
          ),
        ],
      ),
    );
  }
}
