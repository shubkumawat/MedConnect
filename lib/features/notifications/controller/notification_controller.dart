import 'package:get/get.dart';
import '../model/notification_model.dart';

class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
  }

  void _loadNotifications() {
    notifications.value = [
      NotificationModel(
        id: '1',
        title: 'Medication Reminder',
        body: "It's time for your Amlodipine 5mg dose.",
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.medication,
      ),
      NotificationModel(
        id: '2',
        title: 'Appointment Confirmed',
        body: "Your appointment with Dr. Samantha Smith is confirmed for tomorrow at 10:00 AM.",
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.appointment,
      ),
      NotificationModel(
        id: '3',
        title: 'Daily Health Tip',
        body: "Drinking 8 glasses of water a day keeps your skin hydrated and kidneys healthy.",
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.tip,
      ),
    ];
  }

  void markAsRead(String id) {
    int index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      // In a real app, update state/persistence
    }
  }

  void clearAll() {
    notifications.clear();
  }
}
