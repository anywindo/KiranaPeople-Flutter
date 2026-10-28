import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/security/device_security_service.dart';

const _channel = MethodChannel('com.kiranadesainindonesia.kiranapeople/security');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = DeviceSecurityService();

  setUp(() {
    service.resetCache();
    service.allowUnknownInDebug = true;
  });

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  void mockReport(Object? Function(MethodCall) handler) {
    messenger.setMockMethodCallHandler(_channel, (call) async => handler(call));
  }

  group('DeviceSecurityService hardening (MED-03)', () {
    test('clean device is not blocked and sends explicit zero flags', () async {
      mockReport((_) => {
            'rooted': false,
            'hooked': false,
            'emulator': false,
            'debugger': false,
            'signals': <String>[],
          });
      final r = await service.getReport();
      expect(r.status, IntegrityStatus.clean);
      expect(r.shouldBlock, isFalse);
      final f = r.toFormFields();
      expect(f['integrity_status'], 'clean');
      expect(f['is_rooted'], '0');
      expect(f['is_hooked'], '0');
    });

    test('rooted device is blocked', () async {
      mockReport((_) => {'rooted': true, 'signals': ['su_binary']});
      expect(await service.isDeviceCompromised(), isTrue);
      final f = (await service.getReport()).toFormFields();
      expect(f['is_rooted'], '1');
      expect(f['integrity_signals'], 'su_binary');
    });

    test('hooking framework (Frida/Xposed) is blocked', () async {
      mockReport((_) => {'rooted': false, 'hooked': true});
      final r = await service.getReport();
      expect(r.status, IntegrityStatus.compromised);
      expect(r.shouldBlock, isTrue);
    });

    test('native check failure FAILS CLOSED when debug bypass disabled', () async {
      service.allowUnknownInDebug = false;
      mockReport((_) => throw PlatformException(code: 'CHECK_FAILED'));
      final r = await service.getReport();
      expect(r.status, IntegrityStatus.unknown);
      expect(r.shouldBlock, isTrue);
      expect(r.toFormFields()['integrity_status'], 'unknown');
    });

    test('missing plugin fails closed when debug bypass disabled', () async {
      service.allowUnknownInDebug = false;
      expect(await service.isDeviceCompromised(), isTrue);
    });

    test('forceRefresh re-runs the native check instead of trusting cache', () async {
      mockReport((_) => {'rooted': false});
      expect(await service.isDeviceCompromised(), isFalse);
      mockReport((_) => {'hooked': true});
      expect(await service.isDeviceCompromised(), isFalse); // cached
      expect(await service.isDeviceCompromised(forceRefresh: true), isTrue);
    });
  });
}

