import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return PackageInfo(
      appName: 'Kirana People',
      packageName: 'com.kiranadesainindonesia.kiranapeople',
      version: '1.0.2',
      buildNumber: '1',
      buildSignature: '',
    );
  }
});

/// Returns formatted string, e.g. "1.0.2 " or "1.0.2"
final appVersionDisplayProvider = Provider<String>((ref) {
  final infoAsync = ref.watch(packageInfoProvider);
  return infoAsync.maybeWhen(
    data: (info) => info.buildNumber.isNotEmpty
        ? '${info.version} (Build ${info.buildNumber})'
        : info.version,
    orElse: () => '1.0.2 ',
  );
});
