import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              AppColors.primaryDeepBlue,
              AppColors.backgroundDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.accentTeal,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.appName,
                    style: AppTextStyles.poppinsBold28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.tagline,
                    style: AppTextStyles.nunitoItalic14,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  AppStrings.version,
                  style: AppTextStyles.smallWhite70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
