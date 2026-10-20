import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeepBlue,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: const [
                OnboardingSlide(
                  icon: Icons.family_restroom,
                  title: "One App for Your Whole Family's Health",
                  subtitle: "Manage records for everyone in one place.",
                ),
                OnboardingSlide(
                  icon: Icons.qr_code_scanner,
                  title: "Share Instantly with Your Doctor",
                  subtitle: "Fast and secure access to your medical history.",
                ),
                OnboardingSlide(
                  icon: Icons.notifications_active,
                  title: "Never Miss a Dose or Vaccination",
                  subtitle: "Get timely reminders for your health tasks.",
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 20,
              child: TextButton(
                onPressed: controller.skip,
                child: const Text(
                  "Skip",
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: controller.currentPage.value == index ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.currentPage.value == index
                              ? AppColors.accentTeal
                              : AppColors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  )),
            ),
            Obx(() => controller.currentPage.value == 2
                ? Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: controller.skip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "Get Started",
                        style: TextStyle(color: AppColors.white, fontSize: 18),
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const OnboardingSlide({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.accentTeal),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppinsBold24,
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppinsMedium16.copyWith(color: AppColors.grey70),
          ),
        ],
      ),
    );
  }
}
