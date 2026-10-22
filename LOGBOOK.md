# Logbook Pengembangan Kirana People Mobile (Flutter)
**Tanggal**: 21 Oktober 2026  
**Proyek**: Kirana People Flutter App  
**Platform**: Android & iOS  
**Target Backend**: Laravel API (TerribleNight)  

---

## 📌 Ringkasan Eksekutif
Hari ini difokuskan pada penyelarasan aset visual aplikasi, optimasi ukuran & distribusi APK rilis, penyelesaian masalah koneksi jaringan Android Release build (Network Security & ProGuard), audit mendalam terhadap seluruh alur aplikasi (Flaw Audit), pencegahan *memory leak*, serta perbaikan UX dan penanganan *error state*.

---

## 🛠️ Aktivitas & Pencapaian Utama

### 1. Integrasi Branding & Asset Launcher Icon
- **Aset Login**: Mengintegrasikan `logoKiranaSquare.jpeg` dari direktori backend (`TerribleNight/public`) ke layar login [login_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/auth/login_screen.dart).
- **Launcher Icons Multi-Resolusi**:
  - **Android**: Menghasilkan ikon launcher lengkap untuk semua densitas (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) beserta adaptive XML icon (`mipmap-anydpi-v26/ic_launcher.xml`).
  - **iOS**: Memperbarui aset catalog lengkap pada `ios/Runner/Assets.xcassets/AppIcon.appiconset` untuk format standard dan dark icon.

### 2. Optimasi Ukuran & Build APK
- **Masalah Fat APK**: Menemukan APK release standar berukuran ~70 MB akibat penggabungan seluruh Native ABI (armeabi-v7a, arm64-v8a, x86_64).
- **Solusi Split ABI**: Mengimplementasikan build flag `--split-per-abi`, memangkas ukuran APK hingga **~50%**:
  - `app-arm64-v8a-release.apk`: **35.3 MB** *(Target perangkat modern/Samsung S10)*
  - `app-armeabi-v7a-release.apk`: **33.3 MB**
  - `app-x86_64-release.apk`: **37.0 MB**

### 3. Pemecahan Masalah Jaringan di Release Mode ("Terjadi Kesalahan Jaringan")
- **Investigasi Akar Masalah**:
  - Di mode *debug*, Android mengizinkan traffic HTTP dan relaksasi TLS secara default.
  - Di mode *release*, Android 9+ memblokir cleartext HTTP dan memberlakukan verifikasi ketat pada Android Network Security Config.
  - Minifikasi/ProGuard R8 memangkas model refleksi dan secure storage plugin.
- **Implementasi Solusi**:
  - Menambahkan [network_security_config.xml](file:///Users/arw/Git/KiranaPeople-Flutter/android/app/src/main/res/xml/network_security_config.xml) dengan dukungan cleartext untuk domain lokal (`localhost`, `10.0.2.2`, `192.168.1.11`, `terriblenight.test`) dan remote (`terriblenight.onrender.com`).
  - Menambahkan konfigurasi ProGuard [proguard-rules.pro](file:///Users/arw/Git/KiranaPeople-Flutter/android/app/proguard-rules.pro) untuk melindungi Flutter Engine, Flutter Plugins, SharedPreferences (Pigeon/Kotlin coroutines), dan AndroidX Security Crypto.
  - Menyesuaikan [build.gradle.kts](file:///Users/arw/Git/KiranaPeople-Flutter/android/app/build.gradle.kts) dengan `isMinifyEnabled = false` dan konfigurasi Proguard yang bersih.

### 4. Flaw Audit & Bug Fixing (Audit Cacat Menyeluruh)

#### A. Autentikasi & Session Lifecycle
- **Revokasi Token Server-side pada Logout ([auth_repository.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/data/repositories/auth_repository.dart))**:
  - *Sebelumnya*: Local storage dihapus *sebelum* memanggil API `/logout`, sehingga request ke Laravel Sanctum tidak memiliki Bearer token dan token di database tidak pernah terhapus.
  - *Perbaikan*: Endpoint logout dipanggil terlebih dahulu menggunakan token aktif, lalu storage dibersihkan di blok `finally`.
- **In-Memory Cross-Session Leak ([auth_provider.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/providers/auth_provider.dart))**:
  - *Perbaikan*: Saat logout, data `todayAttendanceProvider` dan `historyProvider` di-reset secara eksplisit agar tidak bocor ke akun berikutnya.
- **Fitur Ingat Saya (Remember Me) ([login_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/auth/login_screen.dart))**:
  - *Perbaikan*: Kredensial identifier kini disimpan secara persisten via `SharedPreferences`. Menambahkan aksi keyboard `TextInputAction.next` dan `TextInputAction.done`.
- **Dialog Ubah Password Race Condition ([change_password_dialog.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/profile/change_password_dialog.dart))**:
  - *Perbaikan*: Menambahkan `barrierDismissible: false` dan `PopScope(canPop: !isLoading)` untuk mencegah dialog tertutup saat request sedang berlangsung.

#### B. Jaringan & Interceptor Error
- **Prioritas Error Interceptor ([api_client.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/core/network/api_client.dart))**:
  - *Sebelumnya*: Blok `else if (response.statusCode == 401)` tidak terjangkau karena tertimpa evaluasi `else if (data is Map)`. Selain itu, pesan error bawaan status HTTP menimpa pesan error spesifik dari backend Laravel.
  - *Perbaikan*: Menambahkan pelacakan `hasCustomMessage`. Pesan validasi/penolakan spesifik dari backend selalu dipertahankan, sementara status 401 memicu callback `onUnauthorized` secara andal.
- **Dynamic Origin untuk URL Media ([attendance_event_model.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/data/models/attendance_event_model.dart))**:
  - *Perbaikan*: Mengganti hardcoded domain Render pada `fullSelfieUrl` dengan `ApiConfig.cachedHostOrigin` agar foto riwayat presensi tetap berfungsi pada staging/server lokal.

#### C. Presensi, Geofence, & Kamera
- **False-Positive Radius Geofence ([attendance_confirmation_view.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/attendance/attendance_confirmation_view.dart) & [map_view_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/map/map_view_screen.dart))**:
  - *Sebelumnya*: Jika lokasi GPS null atau Mock Location terdeteksi, UI menampilkan status hijau "Dalam Radius Presensi (0m)".
  - *Perbaikan*: Validasi radius mewajibkan `_currentPosition != null`. Pesan error spesifik (GPS nonaktif, lokasi palsu) ditampilkan dengan tombol coba lagi.
- **Sinkronisasi Otomatis Riwayat Presensi**:
  - *Perbaikan*: Berhasil melakukan submit presensi (dari Beranda maupun Peta) kini otomatis mentrigger `ref.read(historyProvider.notifier).refresh()`.
- **Optimasi Baterai Sensor Kamera ([camera_selfie_view.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/attendance/camera_selfie_view.dart))**:
  - *Perbaikan*: Memanggil `pausePreview()` saat foto selesai diambil agar sensor kamera tidak terus bekerja di latar belakang saat pengguna meninjau foto, serta menambahkan `PopScope` agar tombol back fisik Android mengulang pengambilan foto.

#### D. Pencegahan Memory Leak & Disposal
- Menambahkan pemanggilan `.dispose()` untuk `MapController` pada [map_view_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/map/map_view_screen.dart) dan [attendance_map_modal.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/attendance/attendance_map_modal.dart).
- Menambahkan disposal otomatis untuk `phoneController` pada [profile_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/profile/profile_screen.dart) via `.whenComplete()`.
- Menambahkan proteksi `if (mounted)` pada seluruh listener `FocusNode` dan `TextEditingController` untuk mencegah crash `setState() called after dispose()`.
- Memperbaiki logika paginasi `hasMore: list.length >= 15` dan batas scroll pada [history_provider.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/providers/history_provider.dart) & [history_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/history/history_screen.dart).

#### E. Security Hardening (Peningkatan Keamanan)
- **Anti-Location Replay & Age Verification ([location_helper.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/core/utils/location_helper.dart))**:
  - *Sebelumnya*: Jika GPS timeout, aplikasi mengambil `getLastKnownPosition` tanpa batas waktu (dapat berupa lokasi kemarin saat di kantor).
  - *Perbaikan*: Koordinat cache hanya diterima jika berusia maksimal 10 menit. Jika lebih lama, sistem mewajibkan sinyal GPS baru untuk mencegah manipulasi absensi.
- **Pencegahan Data Extraction via ADB Backup ([AndroidManifest.xml](file:///Users/arw/Git/KiranaPeople-Flutter/android/app/src/main/AndroidManifest.xml))**:
  - *Perbaikan*: Menambahkan `android:allowBackup="false"` sesuai rekomendasi OWASP Mobile Security (M2: Insecure Data Storage).
- **Pengetatan Network Security Config ([network_security_config.xml](file:///Users/arw/Git/KiranaPeople-Flutter/android/app/src/main/res/xml/network_security_config.xml))**:
  - *Perbaikan*: Menonaktifkan cleartext traffic secara global (`base-config cleartextTrafficPermitted="false"`) dan menghapus `usesCleartextTraffic="true"` dari manifest. Cleartext HTTP hanya diizinkan untuk IP pengembangan lokal (`localhost`, `10.0.2.2`, `192.168.1.11`).
- **Pembersihan Log pada Versi Rilis ([api_client.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/core/network/api_client.dart))**:
  - *Perbaikan*: Membungkus error logging dengan `if (kDebugMode)` agar path API dan rincian server tidak bocor ke logcat Android.
- **Validasi Skema URL Ketat ([api_config.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/core/config/api_config.dart))**:
  - *Perbaikan*: Memvalidasi bahwa custom API server hanya menerima skema `http` atau `https`, mencegah potensi URI injection (`file:`, `javascript:`, `content:`).

---

## 📊 Status Akhir Kode & Build
- **Analisis Statis**:
  `flutter analyze` ➡️ **No issues found! (0 warnings, 0 errors)**
- **Artefak Rilis**:
  `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (**35.3 MB**)
- **Target Device Terverifikasi**: Samsung Galaxy S10 (`RR8M20NS5PF`) - Terinstal & Berjalan Sukses.

### 5. Optimasi UX: Subtle Background Refresh (Stale-While-Revalidate)
- **Masalah**: Auto-refresh sebelumnya mereset state ke `AsyncValue.loading()`, menyebabkan UI berkedip (*flicker*), menampilkan spinner layar penuh saat berpindah tab, serta menginterupsi interaksi pengguna setiap 45 detik.
- **Implementasi Solusi**:
  - **SWR (Stale-While-Revalidate)** pada [attendance_provider.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/providers/attendance_provider.dart) & [history_provider.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/providers/history_provider.dart): Menambahkan flag `isBackgroundSyncing`. Jika data sudah ada, UI tidak pernah di-reset ke status *loading*, melainkan tetap tampil utuh sambil memperbarui data di latar belakang.
  - **Non-Intrusive Polling & Tab Sync**: Memperbarui timer background di [attendance_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/attendance/attendance_screen.dart) dan [main_navigation_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/navigation/main_navigation_screen.dart) dengan mode `isBackground: true`.
  - **Micro Progress Bar**: Menambahkan indikator 2px halus di puncak layar yang hanya aktif saat proses sinkronisasi latar belakang berjalan tanpa menyebabkan *layout shift*.

### 6. Pemulihan Homepage Attendance Section Klasik & Pembersihan Login Popup
- **Pemulihan Attendance Section Beranda**:
  - Mengembalikan struktur klasik [attendance_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/attendance/attendance_screen.dart) dengan Segmented Switcher (`Kerja` / `Istirahat`) interaktif, box shift kerja dengan pemilih shift, 2 kolom waktu presensi (`Jam Masuk` / `Jam Pulang` atau `Mulai Istirahat` / `Selesai Istirahat`), thumbnail selfie dinamis, serta tombol aksi kontekstual terintegrasi.
  - Mempertahankan mekanisme *subtle background sync* 60 detik tanpa flicker atau layout shift.
- **Pembersihan Overlay Login**:
  - Menghapus popup/modal overlay saat proses masuk pada [login_screen.dart](file:///Users/arw/Git/KiranaPeople-Flutter/lib/features/auth/login_screen.dart), kembali menggunakan spinner indikator inline yang bersih pada tombol Masuk.

### 7. Penyederhanaan Entry Aktivitas Hari Ini (Beranda)
- **Penghapusan Badge Terpisah**:
  - Menghilangkan badge `Titik Lokasi` dan `Lihat Foto` yang sebelumnya memadati baris entri di kartu "Aktivitas Hari Ini".
- **Interaksi Satu Sentuhan Terpadu**:
  - Membungkus seluruh baris entri dengan `InkWell` interaktif lengkap dengan feedback ripple dan ikon chevron penunjuk (`>`).
  - Mengetuk entri mana pun kini langsung memunculkan modal detail kehadiran yang sama persis seperti pada layar Riwayat (`_showLocationDetail`), lengkap dengan peta 2-pin (posisi user & kantor), radius geofence, status jarak, serta tab foto selfie.
