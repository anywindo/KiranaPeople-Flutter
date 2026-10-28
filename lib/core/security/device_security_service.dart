import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Overall integrity verdict reported to the backend.
enum IntegrityStatus {
  clean('clean'),
  compromised('compromised'),

  /// The native check could not run (error / missing handler). Treated as
  /// blocking in release builds (fail closed).
  unknown('unknown');

  final String value;
  const IntegrityStatus(this.value);
}

/// Snapshot of client-side integrity signals (MASVS-RESILIENCE).
///
/// These are heuristics and can be bypassed on a determined attacker's device.
/// They are sent to the backend as telemetry so the server can make the final
/// decision (and later be replaced by Play Integrity / App Attest).
@immutable
class DeviceSecurityReport {
  final IntegrityStatus status;
  final bool rooted;
  final bool hooked;
  final bool emulator;
  final bool debugger;
  final bool developerMode;
  final bool fakeGpsAppInstalled;
  final String? appSignature;
  final List<String> signals;

  const DeviceSecurityReport({
    required this.status,
    this.rooted = false,
    this.hooked = false,
    this.emulator = false,
    this.debugger = false,
    this.developerMode = false,
    this.fakeGpsAppInstalled = false,
    this.appSignature,
    this.signals = const [],
  });

  /// Attendance must be refused on this device.
  bool get shouldBlock =>
      status != IntegrityStatus.clean || (debugger && !kDebugMode);

  factory DeviceSecurityReport.fromMap(Map<dynamic, dynamic> map) {
    final rooted = map['rooted'] == true;
    final hooked = map['hooked'] == true;
    return DeviceSecurityReport(
      status: (rooted || hooked)
          ? IntegrityStatus.compromised
          : IntegrityStatus.clean,
      rooted: rooted,
      hooked: hooked,
      emulator: map['emulator'] == true,
      debugger: map['debugger'] == true,
      developerMode: map['developerMode'] == true,
      fakeGpsAppInstalled: map['fakeGpsAppInstalled'] == true,
      appSignature: map['appSignature'] as String?,
      signals: (map['signals'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  factory DeviceSecurityReport.unknown(String reason) => DeviceSecurityReport(
    status: IntegrityStatus.unknown,
    signals: ['check_failed:$reason'],
  );

  /// Multipart form fields sent with every attendance event.
  /// Every flag is always sent explicitly so that omission cannot be
  /// mistaken for a clean result.
  Map<String, String> toFormFields() => {
    'integrity_status': status.value,
    'is_rooted': rooted ? '1' : '0',
    'is_hooked': hooked ? '1' : '0',
    'is_emulator': emulator ? '1' : '0',
    'is_debugger': debugger ? '1' : '0',
    'is_developer_mode': developerMode ? '1' : '0',
    'fake_gps_app_installed': fakeGpsAppInstalled ? '1' : '0',
    'integrity_signals': signals.join(','),
    'app_signature': ?appSignature,
  };
}

class DeviceSecurityService {
  static final DeviceSecurityService _instance =
      DeviceSecurityService._internal();
  factory DeviceSecurityService() => _instance;
  DeviceSecurityService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.kiranadesainindonesia.kiranapeople/security');

  /// Short-lived cache so the pre-check and the submit share one result
  /// without letting a stale "clean" verdict persist for the process lifetime
  /// (e.g. hook attached after launch).
  static const Duration _cacheTtl = Duration(seconds: 120);

  DeviceSecurityReport? _cached;
  DateTime? _cachedAt;
  Future<DeviceSecurityReport>? _inFlight;

  /// Allows tests to override the "fail-closed" policy. Defaults to failing
  /// open only in debug builds (unit tests / emulators during development).
  @visibleForTesting
  bool allowUnknownInDebug = true;

  Future<DeviceSecurityReport> getReport({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cached!;
    }

    if (!forceRefresh && _inFlight != null) {
      return _inFlight!;
    }

    final future = _fetchReport();
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  Future<DeviceSecurityReport> _fetchReport() async {
    DeviceSecurityReport report;
    try {
      final map = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSecurityReport',
      );
      report = map == null
          ? DeviceSecurityReport.unknown('null_result')
          : DeviceSecurityReport.fromMap(map);
    } on MissingPluginException {
      report = DeviceSecurityReport.unknown('missing_plugin');
    } on PlatformException catch (e) {
      debugPrint('[DeviceSecurityService] Platform error: $e');
      report = DeviceSecurityReport.unknown('platform_error');
    } catch (e) {
      debugPrint('[DeviceSecurityService] Unexpected error: $e');
      report = DeviceSecurityReport.unknown('unexpected_error');
    }

    // In debug builds (tests, simulators) an unknown result is not blocking;
    // the 'debug_bypass' signal lets the backend see it was not verified.
    if (report.status == IntegrityStatus.unknown &&
        kDebugMode &&
        allowUnknownInDebug) {
      report = DeviceSecurityReport(
        status: IntegrityStatus.clean,
        signals: [...report.signals, 'debug_bypass'],
      );
    }

    _cached = report;
    _cachedAt = DateTime.now();
    return report;
  }

  /// Backward-compatible boolean API. Returns true when attendance should be
  /// blocked (compromised OR check failed in release builds).
  Future<bool> isDeviceCompromised({bool forceRefresh = false}) async {
    final report = await getReport(forceRefresh: forceRefresh);
    return report.shouldBlock;
  }

  /// Checks if Developer Mode is enabled (Android only).
  Future<bool> isDeveloperMode() async {
    try {
      final bool? isDev = await _channel.invokeMethod<bool>('isDeveloperMode');
      return isDev ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Resets cached security state (useful for unit testing).
  @visibleForTesting
  void resetCache() {
    _cached = null;
    _cachedAt = null;
  }
}
