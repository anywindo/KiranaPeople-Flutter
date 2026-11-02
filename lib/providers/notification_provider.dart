import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/notifications/notification_service.dart';

final notificationEnabledProvider =
    NotifierProvider<NotificationNotifier, bool>(NotificationNotifier.new);

class NotificationNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadPreference();
    return true;
  }

  Future<void> _loadPreference() async {
    final enabled = await NotificationService.instance.isEnabled();
    state = enabled;
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    await NotificationService.instance.setEnabled(enabled);
    if (enabled) {
      await NotificationService.instance.requestPermissions();
    }
  }
}
