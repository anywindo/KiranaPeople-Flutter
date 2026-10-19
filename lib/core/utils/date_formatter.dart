import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFullDate(DateTime dateTime) {
    // e.g. "Senin, 19 Oktober 2026"
    final days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dayName = days[dateTime.weekday % 7];
    final monthName = months[dateTime.month];
    return '$dayName, ${dateTime.day} $monthName ${dateTime.year}';
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatTimeWithSeconds(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  static String formatDateYmd(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}j ${mins}m';
    }
    return '${mins}m';
  }
}
