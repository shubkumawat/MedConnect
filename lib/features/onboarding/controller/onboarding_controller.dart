import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  var currentPage = 0.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (currentPage.value < 2) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        _timer?.cancel();
      }
    });
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    _startTimer();
  }

  void skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    Get.offNamed(Routes.LOGIN);
  }

  @override
  void onClose() {
    _timer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
