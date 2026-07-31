import 'package:flutter/material.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, dynamic>> _todayNotifs = const [
    {'title': 'Metformin — time to take your dose', 'time': '8:00 AM', 'icon': Icons.medication, 'color': AppColors.orange, 'highlighted': true},
    {'title': 'Your QR was scanned — Dr. Gupta', 'time': '3:15 PM', 'icon': Icons.qr_code_scanner, 'color': AppColors.primary, 'highlighted': true},
    {'title': 'Aryan — BCG vaccine due in 3 days', 'time': 'Today', 'icon': Icons.vaccines, 'color': AppColors.teal, 'highlighted': false},
  ];

  final List<Map<String, dynamic>> _earlierNotifs = const [
    {'title': 'Follow-up with Dr. Mehra — tomorrow', 'time': 'Reminder', 'icon': Icons.event, 'color': AppColors.accentBlue, 'highlighted': false},
    {'title': 'New Heart Health reel published', 'time': 'New', 'icon': Icons.play_circle_outline, 'color': AppColors.green, 'highlighted': false},
    {'title': 'Priya Kumar — Amlodipine — 10:00 PM', 'time': 'Yesterday', 'icon': Icons.medication, 'color': AppColors.orange, 'highlighted': false},
    {'title': 'Profile 75% complete — Add your allergies', 'time': '2 days ago', 'icon': Icons.person_outline, 'color': AppColors.accentTeal, 'highlighted': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: '🔔 Notifications',
        showBack: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: AppTextStyles.tealLabel),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TODAY
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('TODAY', style: AppTextStyles.captionBold.copyWith(color: AppColors.accentTeal)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._todayNotifs.map((n) => NotificationCard(
            title: n['title'],
            time: n['time'],
            icon: n['icon'],
            iconColor: n['color'],
            isHighlighted: n['highlighted'],
          )),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgCardNavy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('EARLIER', style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._earlierNotifs.map((n) => NotificationCard(
            title: n['title'],
            time: n['time'],
            icon: n['icon'],
            iconColor: n['color'],
            isHighlighted: n['highlighted'],
          )),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
