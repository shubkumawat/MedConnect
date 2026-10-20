import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/profile_setup_controller.dart';

class ProfileSetupStep3Screen extends GetView<ProfileSetupController> {
  const ProfileSetupStep3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Step 3/3", style: AppTextStyles.smallWhite70),
                  Container(
                    width: Get.width * 0.6,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accentTeal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text("Emergency & Details", style: AppTextStyles.poppinsBold28),
              const SizedBox(height: 30),
              
              Text("Emergency Contact", style: AppTextStyles.poppinsMedium16.copyWith(color: AppColors.accentTeal)),
              const SizedBox(height: 16),
              _buildLabel("Name"),
              TextField(
                controller: controller.emergencyNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Contact person name"),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Relation"),
                        TextField(
                          controller: controller.emergencyRelationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("e.g. Spouse"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Mobile"),
                        TextField(
                          controller: controller.emergencyMobileController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("Number"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              Text("Location Info", style: AppTextStyles.poppinsMedium16.copyWith(color: AppColors.accentTeal)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Home City"),
                        TextField(
                          controller: controller.homeCityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("City"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("State"),
                        TextField(
                          controller: controller.homeStateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("State"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text("Insurance Information (Optional)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    TextField(
                      controller: controller.insuranceController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: _inputDecoration("Provider, Policy Number, etc."),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: controller.prevStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentTeal),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Back", style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: controller.nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Finish",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDeepBlue),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: controller.skipForNow,
                  child: Text(
                    "Skip for now",
                    style: AppTextStyles.nunitoItalic14.copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: AppTextStyles.poppinsMedium16),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: AppColors.primaryDeepBlue,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
