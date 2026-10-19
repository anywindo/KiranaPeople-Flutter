import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';

class ServerConfigNotifier extends AsyncNotifier<String> {
  @override
  FutureOr<String> build() async {
    return await ApiConfig.getBaseUrl();
  }

  Future<void> updateServerUrl(String url) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiConfig.setBaseUrl(url);
      return await ApiConfig.getBaseUrl();
    });
  }

  Future<void> resetToDefault() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ApiConfig.resetToDefault();
      return ApiConfig.defaultBaseUrl;
    });
  }
}

final serverConfigProvider =
    AsyncNotifierProvider<ServerConfigNotifier, String>(ServerConfigNotifier.new);
