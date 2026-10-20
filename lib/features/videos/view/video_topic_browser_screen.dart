import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../controller/video_controller.dart';

class VideoTopicBrowserScreen extends StatelessWidget {
  const VideoTopicBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VideoController controller = Get.find<VideoController>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Health Education"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Browse Topics",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              itemCount: controller.topics.length,
              itemBuilder: (context, index) {
                final topic = controller.topics[index];
                return GestureDetector(
                  onTap: () {
                    controller.selectTopic(topic);
                    Get.toNamed(Routes.VIDEO_PLAYER);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDeepBlue,
                          AppColors.primaryDeepBlue.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getTopicIcon(topic), color: AppColors.accentTeal, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTopicIcon(String topic) {
    switch (topic) {
      case "Mental Health": return Icons.psychology;
      case "Nutrition": return Icons.restaurant;
      case "Exercise": return Icons.fitness_center;
      case "Sleep": return Icons.bedtime;
      case "Heart Health": return Icons.favorite;
      case "First Aid": return Icons.medical_services;
      default: return Icons.topic;
    }
  }
}
