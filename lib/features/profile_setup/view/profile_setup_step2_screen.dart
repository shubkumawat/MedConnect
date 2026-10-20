import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/profile_setup_controller.dart';

class ProfileSetupStep2Screen extends GetView<ProfileSetupController> {
  const ProfileSetupStep2Screen({super.key});

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
                  Text("Step 2/3", style: AppTextStyles.smallWhite70),
                  Container(
                    width: Get.width * 0.6,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 2 / 3,
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
              Text("Medical Info", style: AppTextStyles.poppinsBold28),
              const SizedBox(height: 30),
              _buildLabel("Blood Group"),
              DropdownButtonFormField<String>(
                dropdownColor: AppColors.primaryDeepBlue,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Select Blood Group"),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Don\'t Know']
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (val) => controller.updateBloodGroup(val),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Weight"),
                        Obx(() => TextField(
                          controller: controller.weightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(controller.profile.value.weightUnitKg ? "kg" : "lbs").copyWith(
                            suffixIcon: TextButton(
                              onPressed: controller.toggleWeightUnit,
                              child: Text(
                                controller.profile.value.weightUnitKg ? "KG" : "LBS",
                                style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Height"),
                        Obx(() => TextField(
                          controller: controller.heightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(controller.profile.value.heightUnitCm ? "cm" : "ft").copyWith(
                            suffixIcon: TextButton(
                              onPressed: controller.toggleHeightUnit,
                              child: Text(
                                controller.profile.value.heightUnitCm ? "CM" : "FT",
                                style: const TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel("Known Allergies"),
              TextField(
                controller: controller.allergyController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Add allergy...").copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.accentTeal),
                    onPressed: () => controller.addAllergy(controller.allergyController.text),
                  ),
                ),
                onSubmitted: (val) => controller.addAllergy(val),
              ),
              const SizedBox(height: 10),
              Obx(() => Wrap(
                spacing: 8,
                children: controller.profile.value.allergies.map((allergy) => Chip(
                  label: Text(allergy, style: const TextStyle(color: AppColors.primaryDeepBlue)),
                  backgroundColor: AppColors.accentTeal,
                  deleteIcon: const Icon(Icons.close, size: 18, color: AppColors.primaryDeepBlue),
                  onDeleted: () => controller.removeAllergy(allergy),
                )).toList(),
              )),
              const SizedBox(height: 20),
              Obx(() => SwitchListTile(
                title: const Text("Chronic Disease?", style: TextStyle(color: Colors.white)),
                value: controller.profile.value.hasChronicDisease,
                activeColor: AppColors.accentTeal,
                onChanged: controller.setChronicDisease,
                contentPadding: EdgeInsets.zero,
              )),
              Obx(() => SwitchListTile(
                title: const Text("Organ Donor?", style: TextStyle(color: Colors.white)),
                value: controller.profile.value.isOrganDonor,
                activeColor: AppColors.accentTeal,
                onChanged: controller.setOrganDonor,
                contentPadding: EdgeInsets.zero,
              )),
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
                          "Continue",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDeepBlue),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
