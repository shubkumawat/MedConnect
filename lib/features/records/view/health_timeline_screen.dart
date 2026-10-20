import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../model/timeline_event_model.dart';

class HealthTimelineScreen extends StatelessWidget {
  const HealthTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy timeline events
    final events = [
      TimelineEventModel(
        id: '1',
        type: TimelineEventType.doctorVisit,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        title: 'Doctor Visit',
        description: 'Routine checkup with Dr. Sarah Smith at City Hospital.',
      ),
      TimelineEventModel(
        id: '2',
        type: TimelineEventType.medicationAdded,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        title: 'Medication Added',
        description: 'Amlodipine 5mg added to Hypertension records.',
      ),
      TimelineEventModel(
        id: '3',
        type: TimelineEventType.prescriptionUploaded,
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        title: 'Prescription Uploaded',
        description: 'New prescription from Apollo Clinic analyzed by AI.',
      ),
      TimelineEventModel(
        id: '4',
        type: TimelineEventType.diseaseDiagnosed,
        timestamp: DateTime.now().subtract(const Duration(days: 10)),
        title: 'Condition Diagnosed',
        description: 'Type 2 Diabetes confirmed.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text("Health Timeline"),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final showDateHeader = index == 0 || 
              event.timestamp.day != events[index-1].timestamp.day;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateHeader) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _getFormattedDate(event.timestamp),
                    style: AppTextStyles.smallWhite70.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              _buildTimelineTile(event),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentTeal,
        onPressed: () {},
        child: const Icon(Icons.add_comment, color: AppColors.primaryDeepBlue),
      ),
    );
  }

  Widget _buildTimelineTile(TimelineEventModel event) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.white10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(event.type.name.capitalizeFirst!, event.color),
                      Text(
                        "${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return "Today";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day && date.month == yesterday.month && date.year == yesterday.year) {
      return "Yesterday";
    }
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
