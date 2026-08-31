import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/powered_by_aira.dart';
import '../../../data/services/storage_service.dart';
import '../../login/views/login_view.dart';

class _OnboardingStep {
  final String svgAsset;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accent;

  const _OnboardingStep({
    required this.svgAsset,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

const List<_OnboardingStep> _steps = [
  _OnboardingStep(
    svgAsset: 'assets/onboarding/step1_records.svg',
    eyebrow: 'COMPLETE HISTORY',
    title: 'All Your Health Records,\nOne Place',
    subtitle: 'Every diagnosis, prescription and treatment history — organized and always within reach.',
    accent: AppColors.primary,
  ),
  _OnboardingStep(
    svgAsset: 'assets/onboarding/step2_family.svg',
    eyebrow: 'FAMILY CIRCLE',
    title: 'Add Your Whole Family',
    subtitle: 'Manage records for your parents, spouse and children — all from a single account.',
    accent: AppColors.accentBlue,
  ),
  _OnboardingStep(
    svgAsset: 'assets/onboarding/step3_privacy.svg',
    eyebrow: 'BANK-GRADE SECURITY',
    title: 'Private & Secure,\nAlways',
    subtitle: 'Your data is encrypted end-to-end and visible only to you and the family you choose.',
    accent: AppColors.accentOrange,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _breathController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await StorageService().setBool(StorageService.isIntro, true);
    Get.offAll(() => const LoginScreen());
  }

  void _next() {
    if (_currentPage == _steps.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;
    final accent = _steps[_currentPage].accent;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: accent.withOpacity(0.05),
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.07),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, top: 4),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isLast ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: isLast,
                          child: GestureDetector(
                            onTap: _finish,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.textFieldColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Skip',
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.textGray),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double page = _currentPage.toDouble();
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                            page = _pageController.page ?? page;
                          }
                          final delta = (page - index).clamp(-1.0, 1.0);
                          final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(delta * 48, 0),
                              child: child,
                            ),
                          );
                        },
                        child: _buildPage(_steps[index]),
                      );
                    },
                  ),
                ),
                _buildBottomControls(isLast, accent),
                const PoweredByAira(padding: EdgeInsets.only(bottom: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingStep step) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          ScaleTransition(
            scale: Tween(begin: 0.96, end: 1.04).animate(
              CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
            ),
            child: SvgPicture.asset(step.svgAsset, width: 264, height: 264),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: step.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              step.eyebrow,
              style: AppTextStyles.captionBold.copyWith(color: step.accent, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(fontSize: 25, height: 1.25),
          ),
          const SizedBox(height: 12),
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textGray, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(bool isLast, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(_steps.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active ? accent : AppColors.textFieldColor,
                ),
              );
            }),
          ),
          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              height: 56,
              width: isLast ? 172 : 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.tealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isLast ? 1 : 0,
                    child: isLast
                        ? Padding(
                            padding: const EdgeInsets.only(left: 4, right: 8),
                            child: Text(
                              'Get Started',
                              style: AppTextStyles.button,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
