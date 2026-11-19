# Comprehensive Security Audit Report: Kirana People Flutter Codebase

**Target Codebase:** Kirana People (`kirana_people` v1.0.5)  
**Date of Audit:** November 17, 2026  
**Framework:** Flutter (Dart 3.13.5+) / Android Gradle Plugin (AGP 9.1.1, Kotlin 1.9+, Java 17) / iOS Runner (Swift)  
**Audit Standard:** OWASP Mobile Application Security Verification Standard (MASVS v2.0) & OWASP Mobile Top 10 (2024+)  
**Scope:** Client-side source code review, Android/iOS platform configurations, network & transport security, cryptographic posture, secure storage, authentication lifecycle, geolocation & anti-spoofing resilience, and CI/CD pipelines.

---

## 1. Executive Summary

A comprehensive, defense-in-depth security audit of the **Kirana People Flutter application** (version 1.0.5) was conducted. The application is an enterprise workforce management and mobile attendance solution featuring geofencing, camera selfie verification, PDF reporting, and REST API integration with `app.kiranapeople.com`.

The audit evaluated the codebase against all 8 domains of **OWASP MASVS v2.0**:
- **MASVS-STORAGE:** Secure data storage and biometric cache lifecycle.
- **MASVS-CRYPTO:** Key management and cryptographic primitives.
- **MASVS-AUTH:** Authentication mechanisms, token storage, and session invalidation.
- **MASVS-NETWORK:** TLS configuration, network security config, and MitM prevention.
- **MASVS-PLATFORM:** Platform capabilities, sandbox isolation, IPC, and permissions.
- **MASVS-CODE:** Compiler hardening, R8 minification, code obfuscation, and CI/CD hygiene.
- **MASVS-RESILIENCE:** Heuristic anti-root, anti-jailbreak, anti-hooking (Frida/Xposed), mock location, and clock-skew detection.

### Overall Security Posture: **STRONG (Production-Ready with Specific Hardening Opportunities)**

- Automated test suite status: **190/190 tests passing**.
- Static code analysis (`flutter analyze`): **Zero issues found**.
- Previously resolved vulnerabilities (SEC-01 through SEC-06) remain verified and regression-free.
- Three new findings (SEC-12, SEC-13, and SEC-14) have been identified from recent feature additions (file downloading/sharing, dev API endpoint selector, and OTP error handling).

---

## 2. Vulnerability & Findings Tracking Matrix

| ID | Title | OWASP Category | CWE | Severity | Current Status |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **SEC-01** | Android Network Config Trusts User CAs in Production | MASVS-NETWORK | CWE-295 | **High** | ✅ **RESOLVED** |
| **SEC-02** | Release Builds Missing R8 Minification & Secure Keystore | MASVS-CODE | CWE-532 | **High** | ✅ **RESOLVED** |
| **SEC-03** | Attendance GPS Spoofing & Missing Telemetry Signals | MASVS-RESILIENCE | CWE-353 | **Medium** | ✅ **RESOLVED** |
| **SEC-04** | Biometric Attendance Selfie Images Persisting in Cache | MASVS-STORAGE | CWE-312 | **Medium** | ✅ **RESOLVED** |
| **SEC-05** | Absence of Root, Jailbreak & Hooking Telemetry | MASVS-RESILIENCE | CWE-656 | **Medium** | ✅ **RESOLVED** |
| **SEC-06** | Dart Code Obfuscation Flags Missing in CD Pipeline | MASVS-CODE | CWE-656 | **Low** | ✅ **RESOLVED** |
| **SEC-07** | Permissive Location Cache Fallback Window (10 Minutes) | MASVS-RESILIENCE | CWE-353 | **Low** | ⚠️ **OPEN / RECOMMENDED** |
| **SEC-08** | Client-Side Pre-Drop of Blocked Attendance (Missing Server Audit) | MASVS-AUTH | CWE-778 | **Low** | ⚠️ **OPEN / RECOMMENDED** |
| **SEC-09** | Cleartext Dev Hosts Declared in Main Network Security Config | MASVS-NETWORK | CWE-319 | **Low** | ⚠️ **OPEN / RECOMMENDED** |
| **SEC-10** | Missing Biometric App Lock & Inactivity Timeout | MASVS-AUTH | CWE-613 | **Info** | ℹ️ **BACKLOG** |
| **SEC-11** | SSL Public Key Pinning (SPKI) for `app.kiranapeople.com` | MASVS-NETWORK | CWE-295 | **Info** | ℹ️ **BACKLOG** |
| **SEC-12** | Path Traversal / Arbitrary File Overwrite in `FileDownloadHelper` | MASVS-STORAGE | CWE-22 | **Medium** | ✅ **RESOLVED** |
| **SEC-13** | Dev API Configuration UI & Internal IP Leak in Release Mode | MASVS-PLATFORM | CWE-489 | **Low** | ⚠️ **OPEN / RECOMMENDED** |
| **SEC-14** | Client-Side Account Enumeration Leak in Forgot Password Handler | MASVS-AUTH | CWE-204 | **Low** | ⚠️ **OPEN / RECOMMENDED** |

---

## 3. Detailed Audit Findings & Verification

---

### [SEC-01] Android Network Security Config Trusts User CA Certificates in Production
* **Category:** OWASP MASVS-NETWORK / CWE-295 (Improper Certificate Validation)
* **Severity:** **High**
* **Status:** ✅ **RESOLVED**
* **Verification:**
  - In `android/app/src/main/res/xml/network_security_config.xml`, `<base-config>` enforces `cleartextTrafficPermitted="false"` and anchors only `<certificates src="system" />`.
  - User certificates (`<certificates src="user" />`) have been strictly relegated to `<debug-overrides>`, preventing rogue user CAs or proxy profiles from decrypting production traffic on Android 7.0+.
  - In `lib/core/network/api_client.dart`, `ApiClient.shouldAcceptBadCertificate()` strictly returns `false` when `!kDebugMode`.

---

### [SEC-02] Release Builds Missing R8 Minification & Secure Keystore Integration
* **Category:** OWASP MASVS-CODE / MASVS-RESILIENCE / CWE-532
* **Severity:** **High**
* **Status:** ✅ **RESOLVED**
* **Verification:**
  - `android/app/build.gradle.kts` sets `isMinifyEnabled = true` and `isShrinkResources = true` in `buildTypes.release`.
  - ProGuard rules (`android/app/proguard-rules.pro`) preserve JNI and reflection for `flutter_secure_storage`, `shared_preferences`, and Kotlin coroutines.
  - Signing configuration loads dynamically from `key.properties` (or environment variables in `.github/workflows/cd.yml`), falling back safely for local debug runs while preventing accidental debug keystores in published binaries.
  - `.gitignore` explicitly excludes `*.jks`, `*.keystore`, `key.properties`, `*.p8`, `*.p12`, and `.env*`.

---

### [SEC-03] Attendance GPS Spoofing & Missing Telemetry Signals
* **Category:** OWASP MASVS-RESILIENCE / Business Logic Flaws
* **Severity:** **Medium**
* **Status:** ✅ **RESOLVED**
* **Verification:**
  - `LocationHelper.dart` verifies `!position.isMocked`, rejects invalid negative accuracy values (`position.accuracy < 0`), and guards against future clock-skew (`position.timestamp.difference(now).inSeconds > 60`).
  - `AttendanceRepository.submitAttendanceEvent` transmits location telemetry (`is_mocked`, `accuracy`, `altitude`, `device_timestamp`) alongside coordinates in multipart requests.
  - Verified by unit tests in `test/anti_spoofing_security_test.dart`.

---

### [SEC-04] Biometric Attendance Selfie Images Persisting in App Cache
* **Category:** OWASP MASVS-STORAGE / GDPR / ISO 27001 Data Privacy
* **Severity:** **Medium**
* **Status:** ✅ **RESOLVED**
* **Verification:**
  - `CameraSelfieView` and `AttendanceSubmissionDialog` downsample images to 960px @ 75% quality in a background isolate, reducing payload size from ~800 KB to ~150 KB.
  - Post-submission cleanup hooks (`file.deleteSync()` / `await file.delete()`) are implemented across `camera_selfie_view.dart`, `attendance_confirmation_view.dart`, `attendance_submission_dialog.dart`, and `photo_source_sheet.dart` (avatar uploads), preventing biometric face data from accumulating in the internal sandbox.

---

### [SEC-05] Absence of Root, Jailbreak & Hooking Telemetry
* **Category:** OWASP MASVS-RESILIENCE / CWE-656
* **Severity:** **Medium**
* **Status:** ✅ **RESOLVED**
* **Verification:**
  - Dual-platform native integrity method channel implemented (`com.kiranadesainindonesia.kiranapeople/security`):
    - **Android (`MainActivity.kt`):** Detects `su` binaries, test-keys, mounted read-write system partitions, Magisk/KernelSU/APatch directories, memory-mapped hook libraries (`/proc/self/maps`), Xposed bridge classes, active Frida loopback socket (port 27042), and debugger attachment.
    - **iOS (`AppDelegate.swift`):** Detects rootful and rootless jailbreak paths (`/Applications/Cydia.app`, `/var/jb`, `TrollStore`), container sandbox write escapes, system symlinks, `DYLD_INSERT_LIBRARIES`, loaded hooking dynamic libraries (Frida, Substrate, ElleKit), and `P_TRACED` sysctl flags.
  - `DeviceSecurityService` aggregates reports, enforces fail-closed logic in release mode, and transmits explicit boolean flags (`is_rooted`, `is_hooked`, `is_emulator`, `is_debugger`, `is_developer_mode`, `integrity_signals`, `app_signature`).

---

### [SEC-06] Dart Code Obfuscation Flags Missing in CD Pipeline
* **Category:** OWASP MASVS-CODE
* **Severity:** **Low**
* **Status:** ✅ **RESOLVED**
* **Remediation & Verification:**
  - In `.github/workflows/cd.yml`, all release build steps (`Universal APK`, `Split-per-ABI APKs`, and `Android App Bundle`) have been configured with `--obfuscate --split-debug-info=build/app/outputs/symbols`.
  - Staging step automatically packages debug symbol mappings into `app-debug-symbols.zip` and attaches them to GitHub Release assets for crash de-obfuscation (`flutter symbolize`).

---

### [SEC-07] Permissive Location Cache Fallback Window (10 Minutes)
* **Category:** OWASP MASVS-RESILIENCE / Geolocation Integrity
* **Severity:** **Low**
* **Status:** ⚠️ **OPEN / RECOMMENDED**
* **Description:**
  In `lib/core/utils/location_helper.dart` (lines 235-241):
  ```dart
  if (position == null) {
    lastPos ??= await Geolocator.getLastKnownPosition();
    final fallbackNow = DateTime.now();
    if (lastPos != null &&
        fallbackNow.difference(lastPos.timestamp).inMinutes.abs() <= 10) {
      position = lastPos;
    }
  }
  ```
  If satellite and network GPS time out, the client accepts a cached fix up to 10 minutes old. Within 10 minutes, an employee could travel several kilometers outside the office perimeter while checking in.
* **Remediation:**
  Tighten the fallback threshold to 60–120 seconds maximum, or require an explicit user prompt to step near a window/open area for a fresh satellite fix.

---

### [SEC-08] Client-Side Pre-Drop of Blocked Attendance (Missing Server Audit)
* **Category:** OWASP MASVS-AUTH / Security Monitoring & Logging
* **Severity:** **Low**
* **Status:** ⚠️ **OPEN / RECOMMENDED**
* **Description:**
  In `lib/data/repositories/attendance_repository.dart` (lines 61-65):
  ```dart
  if (report.shouldBlock) {
    throw Exception(
      'Perangkat tidak lolos pemeriksaan keamanan. Presensi tidak dapat dilakukan pada perangkat yang dimodifikasi.',
    );
  }
  ```
  When the device is marked compromised, an exception is thrown before `_apiClient.postMultipart` is invoked. While this protects against local spoofing, the backend receives **zero logs** of compromised devices attempting fraudulent attendance.
* **Remediation:**
  Transmit the telemetry to a dedicated security audit endpoint (e.g. `POST /api/v1/security/incident`), or permit the request to proceed with `integrity_status: compromised` so the backend logs the violation and returns HTTP 403.

---

### [SEC-09] Cleartext Development Hosts in Main Network Security Config
* **Category:** OWASP MASVS-NETWORK / Security Misconfiguration
* **Severity:** **Low**
* **Status:** ⚠️ **OPEN / RECOMMENDED**
* **Description:**
  `android/app/src/main/res/xml/network_security_config.xml` includes `<domain-config cleartextTrafficPermitted="true">` for `192.168.1.11`, `192.168.1.48`, and `terriblenight.test`. While limited to LAN/test domains, keeping them in the main configuration file leaves cleartext channels open if base URLs are modified.
* **Remediation:**
  Remove private development domains from `main/res/xml/network_security_config.xml` and retain them only in `debug/res/xml/network_security_config.xml`.

---

### [SEC-10] Lack of Local App Inactivity Timeout & Biometric App Lock
* **Category:** OWASP MASVS-AUTH / CWE-613
* **Severity:** **Info**
* **Status:** ℹ️ **BACKLOG**
* **Description:**
  Sessions remain active until manual logout or 401 token expiry. If an employee's device is left unattended, an unauthorized individual could view history or personal records.
* **Remediation:**
  Integrate `local_auth` for optional biometric app unlock when resuming the app from the background after an idle duration (e.g., 5 minutes).

---

### [SEC-11] Public Key Pinning (SPKI Pinning) for Primary API Host
* **Category:** OWASP MASVS-NETWORK / CWE-295
* **Severity:** **Info**
* **Status:** ℹ️ **BACKLOG**
* **Description:**
  The app enforces system CA validation in release builds, which is standard for commercial mobile apps. For high-security environments, implementing Subject Public Key Info (SPKI) pinning provides defense-in-depth against compromised Certificate Authorities.

---

### [SEC-12] Path Traversal / Arbitrary File Overwrite in `FileDownloadHelper`
* **Category:** OWASP MASVS-STORAGE / CWE-22 (Improper Limitation of a Pathname to a Restricted Directory)
* **Severity:** **Medium**
* **Status:** ✅ **RESOLVED**
* **Verification:**
  - Implemented `FileDownloadHelper.sanitizeFileName()` which strips directory separators (`/`, `\`), resolves and collapses directory traversal sequences (`..`, `....`), strips leading dot/hidden file symbols, and eliminates control characters and illegal filesystem characters.
  - Enforced `sanitizeFileName()` across `extractFileName()`, `downloadFile()`, `_getUniqueFile()`, and `shareFile()`.
  - Added automated security test suite in `test/file_download_helper_test.dart` asserting that relative traversal (`../../etc/passwd`), backslash traversal (`..\..\windows\win.ini`), URL-encoded traversal (`..%2fevil`), and excessive dots (`....//payload.jpg`) are neutralized safely. All tests passing.

---

### [SEC-13] Dev API Configuration UI & Internal IP Leak in Release Mode (NEW)
* **Category:** OWASP MASVS-PLATFORM / CWE-489 (Active Debug Code in Production) / CWE-200 (Information Disclosure)
* **Severity:** **Low**
* **Status:** ⚠️ **OPEN / RECOMMENDED**
* **Description:**
  In `lib/features/auth/login_screen.dart` (lines 70-93 and lines 241-244):
  Tapping the version text 7 times reveals the hidden `DevApiEndpointCard(forceVisible: true)`. Because `forceVisible: true` is passed, it bypasses the `!kDebugMode` condition inside `DevApiEndpointCard.build()`:
  ```dart
  if (!kDebugMode && !widget.forceVisible) {
    return const SizedBox.shrink();
  }
  ```
  While `ApiConfig.getBaseUrl()` internally prevents endpoint modification in release builds (`if (!kDebugMode) return defaultBaseUrl;`), the UI remains fully interactable in production. This:
  1. Discloses private internal network configurations (e.g. `192.168.1.11:8000`, `192.168.1.48:8000`, `terriblenight.test:8000` hardcoded in `dev_api_endpoint_card.dart` lines 364-394).
  2. Confuses end users by displaying "Endpoint API disimpan", while network requests silently ignore it.
* **Remediation:**
  Ensure developer backdoor toggles are completely inactive when `!kDebugMode`:
  ```dart
  void _onVersionTap() {
    if (!kDebugMode) return;
    ...
  }
  ```

---

### [SEC-14] Client-Side Account Enumeration Leak in Forgot Password Handler (NEW)
* **Category:** OWASP MASVS-AUTH / CWE-204 (Observable Response Discrepancy) / OWASP WSTG-IDNT-04
* **Severity:** **Low**
* **Status:** ⚠️ **OPEN / RECOMMENDED**
* **Description:**
  In `lib/data/repositories/auth_repository.dart` (lines 158-169):
  ```dart
  // Guard against unconfirmed/legacy anti-enumeration responses:
  // If the backend message contains "Jika email Anda terdaftar", the email is NOT confirmed.
  // Reject on the UI so unauthorized/unregistered emails cannot advance to the OTP screen.
  if (message.toLowerCase().contains('jika email anda terdaftar')) {
    throw ApiException(
      message: 'Email tidak terdaftar dalam sistem.',
      statusCode: 404,
      errors: {
        'email': ['Email tidak terdaftar dalam sistem.'],
      },
    );
  }
  ```
  Industry standard security controls for password reset endpoints intentionally return neutral messages ("Jika email Anda terdaftar dalam sistem kami, instruksi telah dikirim") to prevent attackers from discovering valid employee email addresses. By intercepting this specific string and surfacing an explicit `Email tidak terdaftar dalam sistem` error, the client compromises the backend's user enumeration protections.
* **Remediation:**
  Align client UX with anti-enumeration principles: allow the generic confirmation message to be displayed, or handle OTP verification uniformly without confirming account existence on the initial submission step.

---

## 4. OWASP MASVS v2.0 Compliance Summary

| Domain | Control Description | Evaluation | Notes |
| :--- | :--- | :---: | :--- |
| **MASVS-STORAGE** | Sensitive Data Storage | **PASS** | `flutter_secure_storage` with Android Keystore & iOS Keychain `first_unlock`. No passwords stored in `SharedPreferences`. |
| **MASVS-STORAGE** | Biometric Data Minimization | **PASS** | Captured selfie images downsampled in isolate and purged upon upload, rejection, or dialog dismissal. |
| **MASVS-STORAGE** | File Path Hygiene | **PASS** | `FileDownloadHelper.sanitizeFileName` neutralizes directory traversal (`..`, `\`, `/`) and illegal characters before file writing. |
| **MASVS-CRYPTO** | Cryptographic Controls | **PASS** | Hardware-backed keystores, SHA-256 integrity digest, standard platform TLS 1.3 ciphers. |
| **MASVS-AUTH** | Authentication & Session | **PASS** | Bearer token architecture, 401 interceptor auto-logout, strict password complexity policy. |
| **MASVS-NETWORK** | Network Communication | **PASS** | Base config enforces system CAs only; user CAs restricted to debug builds; cleartext disabled for production hosts. |
| **MASVS-PLATFORM** | Platform Interaction | **PASS** | `allowBackup="false"`, `taskAffinity=""`, scoped camera & location runtime permissions, package visibility declared. |
| **MASVS-CODE** | Build & Compiler Hardening | **PASS** | R8 code shrinking and resource minification enabled; key.properties release signing; clean `flutter analyze`. |
| **MASVS-RESILIENCE**| Anti-Tamper & Anti-Spoof | **PASS** | Multi-heuristic root/jailbreak detection, Frida/Xposed hooks detection, mock location & GPS telemetry transmission. |

---

## 5. Security Architecture Diagram

```mermaid
flowchart TD
    subgraph Client ["Flutter Mobile Client (v1.0.5)"]
        UI["Attendance Screen & Selfie Capture"]
        DSS["DeviceSecurityService<br/>(Cache TTL: 120s)"]
        LH["LocationHelper<br/>(Mock Detection & Accuracy Filter)"]
        FDH["FileDownloadHelper<br/>(Download & Share Manager)"]
        NC["Native Method Channels<br/>(MainActivity.kt / AppDelegate.swift)"]
        SS["SecureStorageService<br/>(Android Keystore / iOS Keychain)"]
        AC["ApiClient<br/>(Dio + System CA TLS Validator)"]
    end

    subgraph NativeOS ["Operating System Heuristics"]
        RootDetect["Root & Jailbreak Binaries Check"]
        HookDetect["Frida & Xposed Memory/Socket Check"]
        EmuDetect["Hardware & Fingerprint Check"]
        ClockCheck["Timestamp Drift & Mock Flag Check"]
    end

    subgraph BackendCloud ["Enterprise Backend (app.kiranapeople.com)"]
        API["REST API Endpoint (/api/v1/employee/attendance/events)"]
        Audit["Server-Side Telemetry & Geofence Validator"]
        R2["Cloudflare R2 Object Storage"]
    end

    UI -->|"1. Request Location"| LH
    UI -->|"2. Check Device Integrity"| DSS
    DSS <-->|"Invoke Platform Channel"| NC
    NC <--> NativeOS
    LH <--> ClockCheck
    
    UI -->|"3. Build Multipart Payload"| AC
    SS -->|"Inject Bearer Token"| AC
    AC -->|"4. HTTPS TLS 1.3 (System CA)"| API
    API -->|"5. Audit Telemetry & Validate Coordinates"| Audit
    API -->|"6. Store Biometric Selfie"| R2
    
    UI -->|"7. Purge Local Temp Photo"| UI
    UI -->|"8. Export & Preview PDF"| FDH
```

---

## 6. Verification Test Suite Status

The automated security and regression test suite confirms that all security assertions pass:

```bash
$ flutter test
00:15 +190: All tests passed!
```

All 190 tests covering anti-spoofing, certificate validation, biometric cleanup, device integrity, and session lifecycle are passing.
