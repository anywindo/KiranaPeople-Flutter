# Kirana People (Flutter App)

A modern, clean-architecture Flutter application for **Kirana People** Employee Attendance & HRIS Management, built to interface with the **TerribleNight** Laravel Backend API.

---

## 📱 Features

- 🔐 **Authentication & Session Management:**
  - Token-based authentication (Laravel Sanctum) with persistent secure token storage via `flutter_secure_storage`.
  - Automatic session verification on launch with fallback and cancel options.
  - Role awareness and profile synchronization.
- ⏱️ **Real-Time Attendance (Presensi):**
  - Live digital clock with date formatting in Indonesian locale.
  - Dynamic action flows corresponding to backend rules:
    - `START_SHIFT` (Masuk Kerja)
    - `START_BREAK` (Mulai Istirahat)
    - `END_BREAK` (Selesai Istirahat)
    - `END_SHIFT` (Pulang Kerja)
  - **Selfie Camera Capture** verification.
  - **High-accuracy GPS Geolocation** coordinates tagging.
  - Work location radius and assigned shift display.
  - Today's activity timeline.
- 📅 **Attendance History (Riwayat):**
  - Detailed listing of attendance logs and punches.
  - Status indicators (Hadir, Terlambat, dll) with colored badges.
  - Pull-to-refresh synchronization.
- 👤 **Employee Profile:**
  - View employee details, NIK, telephone, work location, and department.
  - In-app password change dialog.
  - Secure logout.
- ⚙️ **Dynamic Server Switcher:**
  - Quick presets:
    - **Render Cloud (Produksi):** `https://terriblenight.onrender.com/api/v1`
    - **Android Emulator Localhost:** `http://10.0.2.2:8000/api/v1`
    - **iOS Simulator / Localhost:** `http://127.0.0.1:8000/api/v1`
    - **Laravel Herd:** `https://terriblenight.test/api/v1`
  - Custom endpoint entry with auto-sanitization.

---

## 🛠️ Architecture & Tech Stack

- **Framework:** Flutter 3.47+ (Dart 3.13+)
- **State Management:** Riverpod 3.x (`flutter_riverpod` with `Notifier` and `AsyncNotifier`)
- **Networking:** `dio` with dynamic baseUrl and Bearer token interceptor
- **Hardware Integration:**
  - `geolocator` (GPS coordinates & permissions)
  - `image_picker` (Selfie capture for attendance)
- **Persistence:**
  - `flutter_secure_storage` (Encrypted tokens & sensitive session)
  - `shared_preferences` (Server endpoint settings)
- **Typography & Styling:**
  - Material 3 with Plus Jakarta Sans via `google_fonts`
  - Kirana signature brand palette (`#FF21A4`, `#F6F7FA`, `#10B981`, `#EF4444`)

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── config/          # ApiConfig and server preset management
│   ├── constants/       # ApiEndpoints
│   ├── network/         # ApiClient (Dio) and error handling
│   ├── storage/         # SecureStorageService
│   ├── theme/           # AppTheme and AppColors
│   └── utils/           # DateFormatter & LocationHelper
├── data/
│   ├── models/          # UserModel, AttendanceModel, Shift, WorkLocation
│   └── repositories/    # AuthRepository & AttendanceRepository
├── providers/           # Riverpod state notifiers (Auth, Attendance, History, ServerConfig)
├── features/
│   ├── auth/            # LoginScreen & ServerSettingsSheet
│   ├── attendance/      # AttendanceScreen & AttendanceSubmissionDialog
│   ├── history/         # HistoryScreen
│   ├── profile/         # ProfileScreen & ChangePasswordDialog
│   └── navigation/      # MainNavigationScreen (Bottom Tab Bar)
└── main.dart            # ProviderScope entry point and RootScreen
```

---

## 🚀 Getting Started

### 1. Prerequisites
Ensure you have the Flutter SDK installed:
```bash
flutter --version
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
- **Android Emulator or Device:**
  ```bash
  flutter run -d android
  ```
- **iOS Simulator or Device:**
  ```bash
  flutter run -d ios
  ```
- **macOS Desktop:**
  ```bash
  flutter run -d macos
  ```

### 4. Run Analysis & Tests
```bash
flutter analyze
flutter test
```
