class ApiErrorLocalizer {
  ApiErrorLocalizer._();

  static String localize(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    if (lower.contains('provided credentials are incorrect') ||
        lower.contains('credentials do not match') ||
        lower.contains('invalid credentials') ||
        lower.contains('these credentials')) {
      return 'Identitas login atau kata sandi yang Anda masukkan salah.';
    }
    if (lower.contains('unauthenticated') ||
        lower.contains('session has expired')) {
      return 'Sesi Anda telah berakhir. Silakan masuk kembali.';
    }
    if (lower.contains('too many attempts') ||
        lower.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Silakan coba lagi dalam beberapa saat.';
    }
    if (lower.contains('given data was invalid') ||
        lower.contains('invalid input')) {
      return 'Data yang dimasukkan tidak valid.';
    }
    if (lower.contains('server error') ||
        lower.contains('internal server error')) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
    }
    if (lower.contains('email has already been taken') ||
        lower.contains('email already exists')) {
      return 'Alamat email sudah terdaftar.';
    }
    if (lower.contains('password must be at least') ||
        lower.contains('password must contain')) {
      return 'Kata sandi minimal 8 karakter.';
    }
    if (lower.contains('password confirmation does not match') ||
        lower.contains('passwords do not match')) {
      return 'Konfirmasi kata sandi tidak cocok.';
    }
    if (lower.contains('field is required')) {
      return 'Kolom ini wajib diisi.';
    }
    if (lower.contains('user not found') || lower.contains('account not found')) {
      return 'Pengguna tidak ditemukan.';
    }
    if (lower.contains('token has expired') || lower.contains('expired token')) {
      return 'Token kedaluwarsa. Silakan ajukan permintaan ulang.';
    }
    if (lower.contains('token is invalid') || lower.contains('invalid token')) {
      return 'Token tidak valid.';
    }
    if (lower.contains('outside the office radius') ||
        lower.contains('outside radius')) {
      return 'Anda berada di luar radius kantor.';
    }
    if (lower.contains('mock location') || lower.contains('fake gps')) {
      return 'Terdeteksi lokasi palsu (Fake GPS). Harap nonaktifkan Fake GPS.';
    }
    if (lower.contains('permission was denied') ||
        lower.contains('location permission')) {
      return 'Izin lokasi ditolak.';
    }

    return trimmed;
  }
}

