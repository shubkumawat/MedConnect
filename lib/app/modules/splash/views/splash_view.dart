import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/app_update_service.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../location/views/location_permission_view.dart';
import '../../login/views/login_view.dart';
import '../../onboarding/views/onboarding_view.dart';
import '../../profile/views/personal_info_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoScale = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));

    final storage = StorageService();
    final isLogin = await storage.getBool(StorageService.isLogin);
    final isIntro = await storage.getBool(StorageService.isIntro);
    final profileSetupDone =
        await storage.getBool(StorageService.profileSetupDone);
    final token = await storage.getString(StorageService.token);

    if (!mounted) return;

    // Destination after splash — never request OS location before this.
    final Widget next;
    if (isLogin) {
      next = const DashboardScreen();
    } else if (token.isNotEmpty && !profileSetupDone) {
      // Resume post-OTP 3-step profile setup (Personal → Medical → Emergency).
      next = const PersonalInfoScreen(null, isFromLogin: true);
    } else if (!isIntro) {
      next = const OnboardingScreen();
    } else {
      next = const LoginScreen();
    }

    final showLocationGate = await LocationPermissionScreen.shouldShow();
    if (!mounted) return;

    if (showLocationGate) {
      Get.offAll(() => LocationPermissionScreen(next: next));
    } else {
      Get.offAll(() => next);
    }

    // Runs after navigation so the "Update Available" dialog (a Get overlay)
    // shows on top of whichever screen the user lands on. Not awaited —
    // a slow/offline store check should never hold up app entry.
    AppUpdateService.instance.checkForUpdate();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo/ic_logo_fulls.png',
                      width: 300,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
