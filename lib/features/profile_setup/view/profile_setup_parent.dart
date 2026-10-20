import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/profile_setup_controller.dart';
import 'profile_setup_step1_screen.dart';
import 'profile_setup_step2_screen.dart';
import 'profile_setup_step3_screen.dart';

class ProfileSetupParent extends GetView<ProfileSetupController> {
  const ProfileSetupParent({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.currentStep.value) {
        case 1:
          return const ProfileSetupStep1Screen();
        case 2:
          return const ProfileSetupStep2Screen();
        case 3:
          return const ProfileSetupStep3Screen();
        default:
          return const ProfileSetupStep1Screen();
      }
    });
  }
}
