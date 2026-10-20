import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controller/video_controller.dart';
import '../model/video_model.dart';

class VideoReelPlayerScreen extends StatelessWidget {
  const VideoReelPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VideoController controller = Get.find<VideoController>();
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: controller.reels.length,
        itemBuilder: (context, index) {
          final video = controller.reels[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Image (Placeholder for video player)
              Image.network(
                video.thumbnailUrl,
                fit: BoxFit.cover,
              ),
              // Overlay Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Back Button
              Positioned(
                top: 50,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Get.back(),
                ),
              ),
              // Video Info
              Positioned(
                bottom: 40,
                left: 20,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        video.topic,
                        style: const TextStyle(
                          color: AppColors.primaryDeepBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "By ${video.physicianName}",
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Positioned(
                bottom: 40,
                right: 15,
                child: Column(
                  children: [
                    _buildActionButton(Icons.favorite_border, "1.2k"),
                    const SizedBox(height: 20),
                    _buildActionButton(Icons.share, "Share"),
                    const SizedBox(height: 20),
                    _buildActionButton(Icons.bookmark_border, "Save"),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
