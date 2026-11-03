import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';

class PrivacyPolicySheet extends StatelessWidget {
  final VoidCallback? onAccept;

  const PrivacyPolicySheet({super.key, this.onAccept});

  static Future<void> show(BuildContext context, {VoidCallback? onAccept}) {
    AppHaptics.light();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacyPolicySheet(onAccept: onAccept),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kebijakan Privasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Kirana People · PT Kirana Desain Indonesia',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'UU PDP No. 27/2022',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.textMutedColor,
                    size: 22,
                  ),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),

          // Scrollable Content
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Quick Highlights Banner
                _buildHighlightsBanner(context),
                const SizedBox(height: 20),

                // Section 1
                _buildSection(
                  context,
                  icon: Icons.gavel_rounded,
                  sectionNumber: '1',
                  title: 'Ruang Lingkup & Landasan Hukum (UU PDP No. 27/2022)',
                  badge: 'Kepatuhan Regulasi',
                  badgeColor: const Color(0xFF3B82F6),
                  content:
                      'Kebijakan Privasi ini mengatur tata cara perolehan, pemrosesan, penyimpanan, dan perlindungan data pribadi para karyawan, staf operasional, dan pihak berkepentingan oleh PT Kirana Desain Indonesia (Kirana Group) selaku Pengendali Data Pribadi.\n\nKebijakan ini disusun berdasarkan Undang-Undang Republik Indonesia Nomor 27 Tahun 2022 tentang Perlindungan Data Pribadi (UU PDP), Peraturan Pemerintah terkait ketenagakerjaan, serta Peraturan Perusahaan Kirana Group.',
                ),
                const SizedBox(height: 14),

                // Section 2
                _buildSection(
                  context,
                  icon: Icons.badge_outlined,
                  sectionNumber: '2',
                  title: 'Data Pribadi yang Kami Kumpulkan & Cara Perolehannya',
                  content:
                      'Dalam menunjang operasional sistem presensi dan manajemen ketenagakerjaan, kami mengumpulkan jenis data berikut secara sah dan proporsional:',
                  bulletPoints: const [
                    'Data Identitas Karyawan: Nama lengkap, Nomor Induk Kependudukan (NIK), Nomor Induk Pegawai/ID Karyawan, alamat email terdaftar, nomor telepon seluler (WhatsApp), tanggal lahir, divisi/departemen, jabatan, dan tanggal bergabung.',
                    'Data Kehadiran & Jadwal Kerja: Waktu check-in, waktu check-out, istirahat masuk/selesai, jadwal shift terpilih, status ketepatan waktu (on-time vs terlambat berdasarkan batas waktu shift), serta catatan dinas luar.',
                    'Data Lokasi Geospasial (GPS): Titik koordinat latitude dan longitude, nilai akurasi horizontal sinyal satelit (dalam satuan meter), dan jarak relatif terhadap geofence kantor saat aksi presensi dilakukan.',
                    'Data Verifikasi Biometrik Citra (Selfie): Foto selfie wajah real-time yang diambil melalui kamera depan perangkat pada saat menekan tombol presensi sebagai bukti keaslian kehadiran.',
                    'Data Integritas Perangkat & Keamanan: Informasi teknis perangkat (merk, model, versi OS Android/iOS), UUID instalasi, status deteksi Root/Jailbreak (standar MASVS-RESILIENCE), status mock location (Fake GPS), dan pendeteksi emulator.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 3
                _buildSection(
                  context,
                  icon: Icons.location_off_rounded,
                  sectionNumber: '3',
                  title: 'Batasan Tegas Terkait Lokasi & Kamera (Anti-Spying)',
                  badge: 'Prinsip Privasi',
                  badgeColor: const Color(0xFF10B981),
                  content:
                      'Kami menghargai privasi dan kemerdekaan personal setiap karyawan. Kirana People menerapkan prinsip perlindungan ketat sebagai berikut:',
                  bulletPoints: const [
                    'Tanpa Pelacakan Lokasi Latar Belakang (No Background Tracking): Koordinat GPS HANYA dibaca secara instan (point-in-time snapshot) saat Anda menekan tombol presensi (Masuk, Istirahat, Pulang). Aplikasi TIDAK melacak jejak rute perjalanan atau memantau lokasi Anda secara kontinu.',
                    'Kamera On-Demand Saja: Akses kamera depan HANYA aktif saat Anda membuka tampilan selfie presensi. Aplikasi TIDAK PERNAH mengakses kamera di latar belakang atau merekam video/audio diam-diam.',
                    'Anti-Manipulasi: Aplikasi dilengkapi filter deteksi Fake GPS dan virtualisasi guna memastikan integritas kehadiran yang adil bagi seluruh staf.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 4
                _buildSection(
                  context,
                  icon: Icons.track_changes_rounded,
                  sectionNumber: '4',
                  title: 'Tujuan Pemrosesan Data Pribadi',
                  content:
                      'Seluruh data yang dikumpulkan hanya diproses untuk tujuan ketenagakerjaan yang sah, meliputi:',
                  bulletPoints: const [
                    'Verifikasi Kehadiran Resmi: Memvalidasi keabsahan kehadiran fisik staf di lokasi kantor/proyek yang ditentukan (geofencing) sesuai jadwal shift kerja.',
                    'Perhitungan Penggajian & Kompensasi: Menjadi dasar perhitungan absensi, keterlambatan, uang lembur, tunjangan kehadiran, dan payroll oleh Divisi SDM & Keuangan.',
                    'Pencegahan Kecurangan (Anti-Fraud): Mencegah praktik titip presensi (buddy-punching), manipulasi titik lokasi, dan peretasan data.',
                    'Pemberitahuan & Pengingat Shift: Mengirimkan pengingat jadwal masuk/pulang serta status keberhasilan sinkronisasi melalui push notification lokal.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 5
                _buildSection(
                  context,
                  icon: Icons.account_circle_outlined,
                  sectionNumber: '5',
                  title: 'Hak-Hak Anda sebagai Subjek Data (Sesuai UU PDP)',
                  badge: 'Hak Anda',
                  badgeColor: AppColors.primary,
                  content:
                      'Berdasarkan Pasal 5 sampai dengan Pasal 13 UU PDP No. 27/2022, Anda selaku Subjek Data memiliki hak-hak yang dijamin hukum:',
                  bulletPoints: const [
                    'Hak Akses Informasi: Mengetahui kejelasan identitas pengendali data, dasar hukum, serta tujuan pemrosesan data pribadi Anda.',
                    'Hak Akses Data Kehadiran: Melihat seluruh riwayat kehadiran harian, waktu check-in/out, dan foto selfie presensi melalui tab "Riwayat" pada aplikasi.',
                    'Hak Koreksi & Pembetulan: Mengajukan penyesuaian atau perbaikan data presensi kepada Divisi SDM/HRD jika terjadi kesalahan sistem atau force majeure.',
                    'Hak Keamanan & Kerahasiaan: Memperoleh jaminan bahwa data pribadi Anda dilindungi dari kebocoran, modifikasi tanpa hak, dan akses ilegal.',
                    'Hak Pengaduan: Menyampaikan pertanyaan atau keluhan mengenai perlindungan data pribadi kepada Manajemen Kirana Group.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 6
                _buildSection(
                  context,
                  icon: Icons.lock_rounded,
                  sectionNumber: '6',
                  title: 'Keamanan, Enkripsi, & Penyimpanan Data',
                  content:
                      'Kami menerapkan standar keamanan teknis dan organisasional tingkat industri guna melindungi data Anda:',
                  bulletPoints: const [
                    'Enkripsi Data dalam Transit: Seluruh pertukaran data antara aplikasi mobile dan server pusat menggunakan protokol HTTPS yang diamankan enkripsi TLS 1.2 / TLS 1.3.',
                    'Penyimpanan Terenkripsi Perangkat: Token otentikasi (JWT) dan kredensial sesi disimpan di Secure Enclave / KeyStore perangkat keras melalui FlutterSecureStorage.',
                    'Penyimpanan Server Berstandar: Basis data dan foto presensi disimpan pada infrastruktur cloud/server aman dengan proteksi firewall berlapis dan pembatasan akses hak (Role-Based Access Control / RBAC).',
                    'Integritas Aplikasi: Aplikasi mendeteksi upaya hooking, reverse engineering, dan perangkat yang terkompromi (Root / Jailbreak).',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 7
                _buildSection(
                  context,
                  icon: Icons.cloud_off_rounded,
                  sectionNumber: '7',
                  title: 'Penyimpanan Offline & Sinkronisasi Lokal',
                  content:
                      'Apabila presensi dilakukan saat koneksi internet terputus atau sinyal seluler lemah di lapangan:',
                  bulletPoints: const [
                    'Data presensi dan foto selfie akan disimpan sementara dalam penyimpanan lokal perangkat yang terenkripsi.',
                    'Saat koneksi internet terhubung kembali, aplikasi secara otomatis melakukan sinkronisasi aman (secure background sync) ke server.',
                    'Data cache sementara di perangkat akan dibersihkan secara aman setelah sinkronisasi berhasil diverifikasi oleh server pusat.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 8
                _buildSection(
                  context,
                  icon: Icons.timer_outlined,
                  sectionNumber: '8',
                  title: 'Masa Retensi & Pemusnahan Data',
                  content:
                      'Data catatan kehadiran dan foto presensi disimpan selama masa kerja karyawan aktif di PT Kirana Desain Indonesia.\n\nSetelah hubungan kerja berakhir, data rekam kehadiran akan diarsipkan selama minimal 3 (tiga) tahun atau sesuai batas retensi dokumen ketenagakerjaan dan audit hukum yang berlaku di Indonesia. Setelah periode retensi terlampaui, data akan dimusnahkan secara permanen atau dianonimkan untuk keperluan statistik agregat.',
                ),
                const SizedBox(height: 14),

                // Section 9
                _buildSection(
                  context,
                  icon: Icons.share_location_rounded,
                  sectionNumber: '9',
                  title: 'Kerahasiaan & Pembagian Data (Zero Third-Party Sharing)',
                  badge: 'Bebas Iklan',
                  badgeColor: const Color(0xFF8B5CF6),
                  content:
                      'PT Kirana Desain Indonesia menegaskan komitmen berikut:',
                  bulletPoints: const [
                    'Tidak Menjual Data: Kami TIDAK PERNAH dan TIDAK AKAN menjual, menyewakan, meminjamkan, atau memperdagangkan data pribadi karyawan kepada pihak ketiga mana pun.',
                    'Tanpa Iklan Pihak Ketiga: Aplikasi ini bersih dari pustaka pelacakan periklanan (ad trackers) atau SDK analitik pihak ketiga yang bersifat komersial.',
                    'Akses Terbatas Internal: Akses data kehadiran dibatasi secara ketat hanya untuk Divisi HRD, atasan langsung yang berwenang, dan administrator sistem TI dengan prinsip "need-to-know basis".',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 10
                _buildSection(
                  context,
                  icon: Icons.perm_device_information_rounded,
                  sectionNumber: '10',
                  title: 'Daftar Izin Perangkat (Device Permissions)',
                  content:
                      'Aplikasi memerlukan izin perangkat berikut dengan alasan penggunaan yang transparan:',
                  bulletPoints: const [
                    'Akses Lokasi (ACCESS_FINE_LOCATION & COARSE): Menghitung jarak perangkat ke titik koordinat kantor saat tombol presensi ditekan guna memvalidasi geofence.',
                    'Akses Kamera (CAMERA): Mengambil foto selfie verifikasi wajah real-time saat presensi.',
                    'Akses Notifikasi (POST_NOTIFICATIONS): Mengirimkan pengingat jadwal shift masuk, istirahat, dan informasi sinkronisasi.',
                    'Akses Jaringan (INTERNET & NETWORK_STATE): Mengirimkan data ke API server Kirana People dan mendeteksi ketersediaan koneksi internet.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 11
                _buildSection(
                  context,
                  icon: Icons.verified_user_rounded,
                  sectionNumber: '11',
                  title: 'Integritas Karyawan & Larangan Pelanggaran',
                  content:
                      'Karyawan wajib menjaga kerahasiaan kata sandi dan integritas data kehadiran pribadi. Tindakan berikut merupakan pelanggaran disiplin berat terhadap Peraturan Perusahaan:',
                  bulletPoints: const [
                    'Meminjamkan atau memberikan akses akun presensi kepada orang lain (titip absen).',
                    'Menggunakan aplikasi pemalsu koordinat (Fake GPS / Mock Location).',
                    'Menggunakan perangkat root / jailbreak atau aplikasi emulator yang dimodifikasi.',
                    'Memanipulasi foto verifikasi wajah menggunakan foto cetak atau citra digital orang lain.',
                  ],
                ),
                const SizedBox(height: 14),

                // Section 12
                _buildSection(
                  context,
                  icon: Icons.contact_support_rounded,
                  sectionNumber: '12',
                  title: 'Kontak Layanan Dukungan & Petugas Perlindungan Data',
                  content:
                      'Apabila Anda memiliki pertanyaan, klarifikasi, atau permohonan terkait perlindungan data pribadi dan penggunaan aplikasi Kirana People, Anda dapat menghubungi:',
                  bulletPoints: const [
                    'Divisi: Human Resources & IT Support (PT Kirana Desain Indonesia)',
                    'Email Bantuan: support@kiranadesainindonesia.com / hr@kiranadesainindonesia.com',
                    'Aplikasi: Kirana People Mobile Attendance System',
                    'Alamat: Kantor Pusat PT Kirana Desain Indonesia (Kirana Group)',
                  ],
                ),
                const SizedBox(height: 20),

                // Footer version note
                Center(
                  child: Text(
                    'Terakhir diperbarui: 3 November 2026 · Versi 2.0 (Lengkap & Terverifikasi)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textMutedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  AppHaptics.medium();
                  Navigator.pop(context);
                  onAccept?.call();
                },
                child: Text(
                  onAccept != null
                      ? 'Saya Telah Membaca & Menyetujui'
                      : 'Saya Mengerti & Tutup',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsBanner(BuildContext context) {
    final isDark = context.isDarkMode;

    final items = [
      (
        icon: Icons.location_off_rounded,
        title: 'Tanpa Background GPS',
        desc: 'Lokasi hanya diambil 1x saat tombol presensi ditekan.',
      ),
      (
        icon: Icons.face_rounded,
        title: 'Selfie Bukti Presensi',
        desc: 'Verifikasi keaslian kehadiran internal tim HRD.',
      ),
      (
        icon: Icons.lock_outline_rounded,
        title: 'Enkripsi Kuat TLS 1.3',
        desc: 'Semua data dan token tersimpan di Secure Keystore.',
      ),
      (
        icon: Icons.shield_outlined,
        title: 'Zero Third-Party Sharing',
        desc: 'Data tidak pernah dijual atau disewakan ke pengiklan.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.30 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ikhtisar Komitmen Privasi Kami',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              height: 1.25,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String sectionNumber,
    required String title,
    String? badge,
    Color? badgeColor,
    required String content,
    List<String>? bulletPoints,
  }) {
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor.withValues(alpha: isDark ? 0.5 : 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$sectionNumber. $title',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.primary)
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: badgeColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: context.textSecondaryColor,
            ),
          ),
          if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...bulletPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
