# Panduan CI/CD GitHub Actions — KiranaPeople Flutter

Dokumen ini menjelaskan arsitektur alur kerja Continuous Integration (CI) dan Continuous Deployment (CD) berbasis **GitHub Actions** untuk aplikasi Flutter KiranaPeople.

---

## 1. Arsitektur Workflow

Tersedia 2 alur kerja terpisah di direktori `.github/workflows/`:

| Workflow | File | Pemicu (Triggers) | Fungsi & Output |
| :--- | :--- | :--- | :--- |
| **CI** | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | `push` & `pull_request` ke cabang `main`, `master`, `develop` | • Validasi sintaks & format kode<br>• Analisis statis (`flutter analyze`)<br>• Unit & Security Tests (`flutter test --coverage`)<br>• Upload artefak laporan cakupan kode (`lcov.info`) |
| **CD** | [`.github/workflows/cd.yml`](.github/workflows/cd.yml) | • Push tag rilis (`v*`, contoh: `v1.0.0`)<br>• Manual trigger (`workflow_dispatch`) | • Build Universal APK (`app-release.apk`)<br>• Build Split ABI APKs (arm64-v8a, armeabi-v7a, x86_64)<br>• Build Android App Bundle (`app-release.aab`) untuk Play Store<br>• Otomatis membuat GitHub Release & mengunggah binary rilis |

---

## 2. Cara Memicu Pipeline

### A. Pengujian Otomatis (CI)
Cukup buat Pull Request (PR) atau lakukan `git push` ke cabang utama (`main`, `master`, atau `develop`). GitHub Actions akan otomatis menjalankan pengujian dan analisis.

### B. Memicu Rilis Otomatis (CD via Git Tag)
Saat versi baru siap dirilis:
```bash
# Buat tag versi baru (mengikuti format Semantic Versioning vX.Y.Z)
git tag v1.0.1

# Dorong tag ke GitHub
git push origin v1.0.1
```
GitHub Actions akan:
1. Menjalankan seluruh test suite.
2. Mengompilasi APK (Universal & Split) dan AAB dengan minifikasi R8.
3. Otomatis membuat rilis di tab **Releases** GitHub dan melampirkan seluruh binary instalasi.

### C. Memicu Build Manual (CD via GitHub UI)
1. Buka repositori di GitHub.
2. Masuk ke tab **Actions** > Pilih **Continuous Deployment (CD)**.
3. Klik tombol **Run workflow**.
4. Pilih cabang dan target build (`all`, `apk`, atau `appbundle`).
5. Unduh binary hasil kompilasi langsung dari halaman detail run.

---

## 3. Konfigurasi Keystore Rilis (GitHub Secrets)

Pipeline telah dirancang aman:
- **Jika secret belum diatur:** Build tetap berhasil dikompilasi menggunakan signature debug fallback.
- **Untuk rilis produksi resmi (Play Store):** Tambahkan secret berikut di GitHub (**Settings > Secrets and variables > Actions > New repository secret**):

| Nama Secret | Deskripsi | Cara Mendapatkan |
| :--- | :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | File keystore `.jks` yang di-encode ke base64 | Jalankan di terminal: `base64 -i android/app/upload-keystore.jks \| pbcopy` (macOS) atau `base64 -w 0 upload-keystore.jks` (Linux) |
| `ANDROID_KEY_ALIAS` | Alias kunci di dalam keystore | Contoh: `upload` atau `kirana_key` |
| `ANDROID_STORE_PASSWORD` | Password keystore | Password yang digunakan saat membuat keystore |
| `ANDROID_KEY_PASSWORD` | Password private key | Password kunci (biasanya sama dengan store password) |

*Alternatif: Anda juga dapat memasukkan seluruh isi `key.properties` ke dalam secret `ANDROID_KEY_PROPERTIES`.*

---

## 4. Keamanan Pipeline (Security Hardening)
- **Token Permissions:** Menggunakan prinsip least privilege (`contents: write` hanya pada job rilis).
- **Concurrency Control:** Membatalkan build lama secara otomatis jika ada commit baru pada PR yang sama (`cancel-in-progress: true`).
- **Dependency Caching:** Cache cerdas untuk Flutter SDK dan Gradle dependencies guna memangkas waktu build hingga 60%.
