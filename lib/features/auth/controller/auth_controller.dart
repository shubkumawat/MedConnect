import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';

class AuthController extends GetxController {
  final mobileNumberController = TextEditingController();
  final otpControllers = List.generate(6, (index) => TextEditingController());
  final otpFocusNodes = List.generate(6, (index) => FocusNode());
  
  var countdown = 60.obs;
  Timer? _timer;

  void startTimer() {
    countdown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  void sendOtp() {
    if (mobileNumberController.text.length == 10) {
      Get.toNamed(Routes.OTP);
      startTimer();
    } else {
      Get.snackbar("Error", "Please enter a valid 10-digit mobile number",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      otpFocusNodes[index + 1].requestFocus();
    }
    
    String otp = otpControllers.map((e) => e.text).join();
    if (otp.length == 6) {
      verifyOtp();
    }
  }

  void verifyOtp() {
    // Mock verification
    String otp = otpControllers.map((e) => e.text).join();
    if (otp == "123456") {
      Get.offAllNamed(Routes.PROFILE_SETUP);
    } else {
      Get.snackbar("Error", "Invalid OTP", snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    mobileNumberController.dispose();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    super.onClose();
  }
}
