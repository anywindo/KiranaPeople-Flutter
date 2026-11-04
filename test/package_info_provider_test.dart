import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:kirana_people/providers/package_info_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('packageInfoProvider & appVersionDisplayProvider Tests', () {
    test('appVersionDisplayProvider formats version and build number correctly', () async {
      final container = ProviderContainer(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) => Future.value(
              PackageInfo(
                appName: 'Kirana People',
                packageName: 'com.kiranadesainindonesia.kiranapeople',
                version: '1.0.2',
                buildNumber: '1',
                buildSignature: '',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(packageInfoProvider.future);
      final displayVersion = container.read(appVersionDisplayProvider);
      expect(displayVersion, equals('1.0.2 '));
    });

    test('appVersionDisplayProvider formats without build number if buildNumber is empty', () async {
      final container = ProviderContainer(
        overrides: [
          packageInfoProvider.overrideWith(
            (ref) => Future.value(
              PackageInfo(
                appName: 'Kirana People',
                packageName: 'com.kiranadesainindonesia.kiranapeople',
                version: '2.0.0',
                buildNumber: '',
                buildSignature: '',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(packageInfoProvider.future);
      final displayVersion = container.read(appVersionDisplayProvider);
      expect(displayVersion, equals('2.0.0'));
    });

    test('packageInfoProvider default fallback works safely when platform throws', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final info = await container.read(packageInfoProvider.future);
      expect(info.version, isNotEmpty);
      expect(info.appName, equals('Kirana People'));
    });
  });
}

