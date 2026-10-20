import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../controller/notification_controller.dart';
import '../model/notification_model.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController controller = Get.find<NotificationController>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Notification Center"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => controller.clearAll(),
            child: const Text("Clear All", style: TextStyle(color: AppColors.accentTeal)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  "No notifications yet",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: controller.notifications.length,
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getIconColor(notification.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(notification.type),
                    color: _getIconColor(notification.type),
                  ),
                ),
                title: Text(
                  notification.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('hh:mm a').format(notification.timestamp),
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.medication: return Icons.medication;
      case NotificationType.appointment: return Icons.event_available;
      case NotificationType.tip: return Icons.lightbulb_outline;
      case NotificationType.alert: return Icons.warning_amber_rounded;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.medication: return AppColors.accentTeal;
      case NotificationType.appointment: return Colors.blue;
      case NotificationType.tip: return Colors.orange;
      case NotificationType.alert: return Colors.red;
    }
  }
}
