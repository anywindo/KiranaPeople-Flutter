import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PrivacyHighlight {
  final IconData icon;
  final String title;
  final String desc;

  const PrivacyHighlight({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class PrivacyPolicySection {
  final IconData icon;
  final String sectionNumber;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final String content;
  final List<String>? bulletPoints;

  const PrivacyPolicySection({
    required this.icon,
    required this.sectionNumber,
    required this.title,
    this.badge,
    this.badgeColor,
    required this.content,
    this.bulletPoints,
  });
}

const List<PrivacyHighlight> privacyHighlights = [
  PrivacyHighlight(
    icon: Icons.location_off_rounded,
    title: 'Tanpa Background GPS',
    desc: 'Lokasi hanya diambil 1x saat tombol presensi ditekan.',
  ),
  PrivacyHighlight(
    icon: Icons.face_rounded,
    title: 'Selfie Bukti Presensi',
    desc: 'Verifikasi keaslian kehadiran internal tim HRD.',
  ),
  PrivacyHighlight(
    icon: Icons.lock_outline_rounded,
    title: 'Enkripsi Kuat TLS 1.3',
    desc: 'Semua data dan token tersimpan di Secure Keystore.',
  ),
  PrivacyHighlight(
    icon: Icons.shield_outlined,
    title: 'Zero Third-Party Sharing',
    desc: 'Data tidak pernah dijual atau disewakan ke pengiklan.',
  ),
];

const List<PrivacyPolicySection> privacySections = [
  PrivacyPolicySection(
    icon: Icons.gavel_rounded,
    sectionNumber: '1',
    title: 'Ruang Lingkup & Landasan Hukum (UU PDP No. 27/2022)',
    badge: 'Kepatuhan Regulasi',
    badgeColor: Color(0xFF3B82F6),
    content: 'Kebijakan Privasi ini mengatur tata cara perolehan, pemrosesan, penyimpanan, dan perlindungan data pribadi para karyawan, staf operasional, dan pihak berkepentingan oleh PT Kirana Desain Indonesia (Kirana Group) selaku Pengendali Data Pribadi.\n\nKebijakan ini disusun berdasarkan Undang-Undang Republik Indonesia Nomor 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP), Peraturan Pemerintah terkait ketenagakerjaan, serta Peraturan Perusahaan Kirana Group.',
  ),
  PrivacyPolicySection(
    icon: Icons.badge_outlined,
    sectionNumber: '2',
    title: 'Data Pribadi yang Kami Kumpulkan & Cara Perolehannya',
    content: 'Dalam menunjang operasional sistem presensi dan manajemen ketenagakerjaan, kami mengumpulkan jenis data berikut secara sah dan proporsional:',
    bulletPoints: [
      'Data Identitas Karyawan: Nama lengkap, Nomor Induk Kependudukan (NIK), Nomor Induk Pegawai/ID Karyawan, alamat email terdaftar, nomor telepon seluler (WhatsApp), tanggal lahir, divisi/departemen, jabatan, dan tanggal bergabung.',
      'Data Kehadiran & Jadwal Kerja: Waktu check-in, waktu check-out, istirahat masuk/selesai, jadwal shift terpilih, status ketepatan waktu (on-time vs terlambat berdasarkan batas waktu shift), serta catatan dinas luar.',
      'Data Lokasi Geospasial (GPS): Titik koordinat latitude dan longitude, nilai akurasi horizontal sinyal satelit (dalam satuan meter), dan jarak relatif terhadap geofence kantor saat aksi presensi dilakukan.',
      'Data Verifikasi Biometrik Citra (Selfie): Foto selfie wajah real-time yang diambil melalui kamera depan perangkat pada saat menekan tombol presensi sebagai bukti keaslian kehadiran.',
      'Data Integritas Perangkat & Keamanan: Informasi teknis perangkat (merk, model, versi OS Android/iOS), UUID instalasi, status deteksi Root/Jailbreak (standar MASVS-RESILIENCE), status mock location (Fake GPS), dan pendeteksi emulator.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.location_off_rounded,
    sectionNumber: '3',
    title: 'Batasan Tegas Terkait Lokasi & Kamera (Anti-Spying)',
    badge: 'Prinsip Privasi',
    badgeColor: Color(0xFF10B981),
    content: 'Kami menghargai privasi dan kemerdekaan personal setiap karyawan. Kirana People menerapkan prinsip perlindungan ketat sebagai berikut:',
    bulletPoints: [
      'Tanpa Pelacakan Lokasi Latar Belakang (No Background Tracking): Koordinat GPS HANYA dibaca secara instan (point-in-time snapshot) saat Anda menekan tombol presensi (Masuk, Istirahat, Pulang). Aplikasi TIDAK melacak jejak rute perjalanan atau memantau lokasi Anda secara kontinu.',
      'Kamera On-Demand Saja: Akses kamera depan HANYA aktif saat Anda membuka tampilan selfie presensi. Aplikasi TIDAK PERNAH mengakses kamera di latar belakang atau merekam video/audio diam-diam.',
      'Anti-Manipulasi: Aplikasi dilengkapi filter deteksi Fake GPS dan virtualisasi guna memastikan integritas kehadiran yang adil bagi seluruh staf.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.track_changes_rounded,
    sectionNumber: '4',
    title: 'Tujuan Pemrosesan Data Pribadi',
    content: 'Seluruh data yang dikumpulkan hanya diproses untuk tujuan ketenagakerjaan yang sah, meliputi:',
    bulletPoints: [
      'Verifikasi Kehadiran Resmi: Memvalidasi keabsahan kehadiran fisik staf di lokasi kantor/proyek yang ditentukan (geofencing) sesuai jadwal shift kerja.',
      'Perhitungan Penggajian & Kompensasi: Menjadi dasar perhitungan absensi, keterlambatan, uang lembur, tunjangan kehadiran, dan payroll oleh Divisi SDM & Keuangan.',
      'Pencegahan Kecurangan (Anti-Fraud): Mencegah praktik titip presensi (buddy-punching), manipulasi titik lokasi, dan peretasan data.',
      'Pemberitahuan & Pengingat Shift: Mengirimkan pengingat jadwal masuk/pulang serta status keberhasilan sinkronisasi melalui push notification lokal.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.account_circle_outlined,
    sectionNumber: '5',
    title: 'Hak-Hak Anda sebagai Subjek Data (Sesuai UU PDP)',
    badge: 'Hak Anda',
    badgeColor: AppColors.primary,
    content: 'Berdasarkan Pasal 5 sampai dengan Pasal 13 UU PDP No. 27/2022, Anda selaku Subjek Data memiliki hak-hak yang dijamin hukum:',
    bulletPoints: [
      'Hak Akses Informasi: Mengetahui kejelasan identitas pengendali data, dasar hukum, serta tujuan pemrosesan data pribadi Anda.',
      'Hak Akses Data Kehadiran: Melihat seluruh riwayat kehadiran harian, waktu check-in/out, dan foto selfie presensi melalui tab "Riwayat" pada aplikasi.',
      'Hak Koreksi & Pembetulan: Mengajukan penyesuaian atau perbaikan data presensi kepada Divisi SDM/HRD jika terjadi kesalahan sistem atau force majeure.',
      'Hak Keamanan & Kerahasiaan: Memperoleh jaminan bahwa data pribadi Anda dilindungi dari kebocoran, modifikasi tanpa hak, dan akses ilegal.',
      'Hak Pengaduan: Menyampaikan pertanyaan atau keluhan mengenai perlindungan data pribadi kepada Manajemen Kirana Group.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.lock_rounded,
    sectionNumber: '6',
    title: 'Keamanan, Enkripsi, & Penyimpanan Data',
    content: 'Kami menerapkan standar keamanan teknis dan organisasional tingkat industri guna melindungi data Anda:',
    bulletPoints: [
      'Enkripsi Data dalam Transit: Seluruh pertukaran data antara aplikasi mobile dan server pusat menggunakan protokol HTTPS yang diamankan enkripsi TLS 1.2 / TLS 1.3.',
      'Penyimpanan Terenkripsi Perangkat: Token otentikasi (JWT) dan kredensial sesi disimpan di Secure Enclave / KeyStore perangkat keras melalui FlutterSecureStorage.',
      'Penyimpanan Server Berstandar: Basis data dan foto presensi disimpan pada infrastruktur cloud/server aman dengan proteksi firewall berlapis dan pembatasan akses hak (Role-Based Access Control / RBAC).',
      'Integritas Aplikasi: Aplikasi mendeteksi upaya hooking, reverse engineering, dan perangkat yang terkompromi (Root / Jailbreak).',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.cloud_off_rounded,
    sectionNumber: '7',
    title: 'Penyimpanan Offline & Sinkronisasi Lokal',
    content: 'Apabila presensi dilakukan saat koneksi internet terputus atau sinyal seluler lemah di lapangan:',
    bulletPoints: [
      'Data presensi dan foto selfie akan disimpan sementara dalam penyimpanan lokal perangkat yang terenkripsi.',
      'Saat koneksi internet terhubung kembali, aplikasi secara otomatis melakukan sinkronisasi aman (secure background sync) ke server.',
      'Data cache sementara di perangkat akan dibersihkan secara aman setelah sinkronisasi berhasil diverifikasi oleh server pusat.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.timer_outlined,
    sectionNumber: '8',
    title: 'Masa Retensi & Pemusnahan Data',
    content: 'Data catatan kehadiran dan foto presensi disimpan selama masa kerja karyawan aktif di PT Kirana Desain Indonesia.\n\nSetelah hubungan kerja berakhir, data rekam kehadiran akan diarsipkan selama minimal 3 (tiga) tahun atau sesuai batas retensi dokumen ketenagakerjaan dan audit hukum yang berlaku di Indonesia. Setelah periode retensi terlampaui, data akan dimusnahkan secara permanen atau dianonimkan untuk keperluan statistik agregat.',
  ),
  PrivacyPolicySection(
    icon: Icons.share_location_rounded,
    sectionNumber: '9',
    title: 'Kerahasiaan & Pembagian Data (Zero Third-Party Sharing)',
    badge: 'Bebas Iklan',
    badgeColor: Color(0xFF8B5CF6),
    content: 'PT Kirana Desain Indonesia menegaskan komitmen berikut:',
    bulletPoints: [
      'Tidak Menjual Data: Kami TIDAK PERNAH dan TIDAK AKAN menjual, menyewakan, meminjamkan, atau memperdagangkan data pribadi karyawan kepada pihak ketiga mana pun.',
      'Tanpa Iklan Pihak Ketiga: Aplikasi ini bersih dari pustaka pelacakan periklanan (ad trackers) atau SDK analitik pihak ketiga yang bersifat komersial.',
      'Akses Terbatas Internal: Akses data kehadiran dibatasi secara ketat hanya untuk Divisi HRD, atasan langsung yang berwenang, dan administrator sistem TI dengan prinsip "need-to-know basis".',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.perm_device_information_rounded,
    sectionNumber: '10',
    title: 'Daftar Izin Perangkat (Device Permissions)',
    content: 'Aplikasi memerlukan izin perangkat berikut dengan alasan penggunaan yang transparan:',
    bulletPoints: [
      'Akses Lokasi (ACCESS_FINE_LOCATION & COARSE): Menghitung jarak perangkat ke titik koordinat kantor saat tombol presensi ditekan guna memvalidasi geofence.',
      'Akses Kamera (CAMERA): Mengambil foto selfie verifikasi wajah real-time saat presensi.',
      'Akses Notifikasi (POST_NOTIFICATIONS): Mengirimkan pengingat jadwal shift masuk, istirahat, dan informasi sinkronisasi.',
      'Akses Jaringan (INTERNET & NETWORK_STATE): Mengirimkan data ke API server Kirana People dan mendeteksi ketersediaan koneksi internet.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.verified_user_rounded,
    sectionNumber: '11',
    title: 'Integritas Karyawan & Larangan Pelanggaran',
    content: 'Karyawan wajib menjaga kerahasiaan kata sandi dan integritas data kehadiran pribadi. Tindakan berikut merupakan pelanggaran disiplin berat terhadap Peraturan Perusahaan:',
    bulletPoints: [
      'Meminjamkan atau memberikan akses akun presensi kepada orang lain (titip absen).',
      'Menggunakan aplikasi pemalsu koordinat (Fake GPS / Mock Location).',
      'Menggunakan perangkat root / jailbreak atau aplikasi emulator yang dimodifikasi.',
      'Memanipulasi foto verifikasi wajah menggunakan foto cetak atau citra digital orang lain.',
    ],
  ),
  PrivacyPolicySection(
    icon: Icons.contact_support_rounded,
    sectionNumber: '12',
    title: 'Kontak Layanan Dukungan & Petugas Perlindungan Data',
    content: 'Apabila Anda memiliki pertanyaan, klarifikasi, atau permohonan terkait perlindungan data pribadi dan penggunaan aplikasi Kirana People, Anda dapat menghubungi:',
    bulletPoints: [
      'Divisi: Human Resources & IT Support (PT Kirana Desain Indonesia)',
      'Email Bantuan: support@kiranadesainindonesia.com / hr@kiranadesainindonesia.com',
      'Aplikasi: Kirana People Mobile Attendance System',
      'Alamat: Kantor Pusat PT Kirana Desain Indonesia (Kirana Group)',
    ],
  ),
];
