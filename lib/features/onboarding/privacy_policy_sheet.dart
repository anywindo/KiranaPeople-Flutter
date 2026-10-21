import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicySheet extends StatelessWidget {
  final VoidCallback? onAccept;

  const PrivacyPolicySheet({super.key, this.onAccept});

  static Future<void> show(BuildContext context, {VoidCallback? onAccept}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PrivacyPolicySheet(onAccept: onAccept),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kebijakan Privasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Scrollable Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection(
                  icon: Icons.location_on_rounded,
                  title: '1. Pengumpulan Data Lokasi (GPS & Geofence)',
                  content:
                      'Aplikasi ini memproses koordinat lokasi (latitude dan longitude) perangkat Anda untuk memvalidasi bahwa presensi masuk, istirahat, dan pulang dilakukan di dalam batas radius area kantor kerja yang sah. Data lokasi hanya diambil saat proses presensi berlangsung dan tidak dilacak di latar belakang secara sembarangan. Aplikasi secara otomatis mendeteksi lokasi tiruan (Fake GPS).',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.camera_alt_rounded,
                  title: '2. Verifikasi Foto Wajah & Kamera',
                  content:
                      'Untuk menjamin keaslian dan mencegah manipulasi presensi, aplikasi memerlukan akses kamera depan untuk mengambil foto selfie real-time saat melakukan presensi. Foto diunggah dan disimpan secara terenkripsi pada server perusahaan sebagai bukti kehadiran resmi dan audit tim SDM/HR.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.lock_outline_rounded,
                  title: '3. Keamanan Kata Sandi & Akun',
                  content:
                      'Kata sandi yang Anda buat pada tahap aktivasi ini dienkripsi menggunakan standar keamanan industri. Anda bertanggung jawab penuh atas kerahasiaan kata sandi Anda dan dilarang memberikan akses akun kepada pihak lain. Token otentikasi disimpan dengan aman pada penyimpanan terenkripsi perangkat Anda.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.dns_rounded,
                  title: '4. Penyimpanan & Kerahasiaan Data',
                  content:
                      'Seluruh data riwayat kehadiran, waktu kerja, dan foto presensi disimpan secara aman di infrastruktur server perusahaan. Data hanya dapat diakses oleh petugas HR dan pimpinan yang berwenang, serta tidak akan pernah dibagikan atau diperjualbelikan kepada pihak ketiga.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.verified_user_rounded,
                  title: '5. Integritas Presensi & Kepatuhan',
                  content:
                      'Karyawan berkewajiban mencatat kehadiran secara tertib dan berurutan sesuai jam kerja dan jadwal istirahat. Segala bentuk manipulasi data kehadiran, penggunaan emulator, atau kecurangan biometrik akan dikenakan tindakan disipliner sesuai peraturan kepegawaian perusahaan.',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Action
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                  Navigator.pop(context);
                  onAccept?.call();
                },
                child: const Text(
                  'Saya Mengerti & Setuju',
                  style: TextStyle(
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
