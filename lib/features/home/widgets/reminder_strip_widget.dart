import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ReminderStripWidget extends GetView<HomeController> {
  const ReminderStripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Today's Reminders", style: AppTextStyles.poppinsMedium16),
        ),
        SizedBox(
          height: 90,
          child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: controller.reminders.length,
            itemBuilder: (context, index) {
              final reminder = controller.reminders[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeepBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warningOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(reminder['icon'] ?? '💊', style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            reminder['title'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            reminder['time'] ?? '',
                            style: TextStyle(color: AppColors.warningOrange, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            reminder['desc'] ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )),
        ),
      ],
    );
  }
}
