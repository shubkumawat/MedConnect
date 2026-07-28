import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../login/views/login_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _heartController;
  late AnimationController _fadeController;
  late Animation<double> _heartScale;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _heartScale = Tween(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );

    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    final isLogin = await StorageService().getBool(StorageService.isLogin);

    if (!mounted) return;

    if (!isLogin) {
      Get.offAll(() => const LoginScreen());
    } else {
      // Temporarily going to DashboardScreen as per original logic if onboarding is skipped/not ready
      Get.offAll(() => const DashboardScreen());
      // Replace with: Get.offAll(() => const OnboardingView());
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              AppColors.bgDeepNavy,
              AppColors.bgDeepNavy,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _heartScale,
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.accentTeal,
                      size: 62,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Med Connect', style: AppTextStyles.heading1.copyWith(fontSize: 30)),
              const SizedBox(height: 10),
              Text(
                'Your Health. Your Family. Your Record.',
                style: AppTextStyles.body.copyWith(color: AppColors.accentTeal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _heartController,
                    builder: (_, __) {
                      final t = (_heartController.value + i * 0.3) % 1.0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentTeal.withOpacity(0.4 + t * 0.6),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 80),
              Column(
                children: [
                  Text('v1.0.0 · AIRA Innovations', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
