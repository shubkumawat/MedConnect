import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/profile_setup_controller.dart';

class ProfileSetupStep1Screen extends GetView<ProfileSetupController> {
  const ProfileSetupStep1Screen({super.key});

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
                  Text("Step 1/3", style: AppTextStyles.smallWhite70),
                  Container(
                    width: Get.width * 0.6,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1 / 3,
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
              Text("Personal Info", style: AppTextStyles.poppinsBold28),
              const SizedBox(height: 30),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryDeepBlue,
                      child: Icon(Icons.person, size: 60, color: AppColors.white.withOpacity(0.5)),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accentTeal,
                        child: Icon(Icons.camera_alt, size: 18, color: AppColors.primaryDeepBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildLabel("Full Name"),
              TextField(
                controller: controller.nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Enter your name"),
              ),
              const SizedBox(height: 20),
              _buildLabel("Date of Birth"),
              Obx(() => InkWell(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) controller.updateDob(picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        controller.profile.value.dob == null
                            ? "Select Date"
                            : "${controller.profile.value.dob!.day}/${controller.profile.value.dob!.month}/${controller.profile.value.dob!.year}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Icon(Icons.calendar_today, color: AppColors.accentTeal, size: 20),
                    ],
                  ),
                ),
              )),
              if (controller.profile.value.dob != null) ...[
                const SizedBox(height: 8),
                Text("Age: ${controller.profile.value.age} years", style: AppTextStyles.nunitoItalic14),
              ],
              const SizedBox(height: 20),
              _buildLabel("Gender"),
              Obx(() => Row(
                children: [
                  _genderPill("Male"),
                  const SizedBox(width: 8),
                  _genderPill("Female"),
                  const SizedBox(width: 8),
                  _genderPill("Other"),
                ],
              )),
              const SizedBox(height: 20),
              _buildLabel("Nationality"),
              DropdownButtonFormField<String>(
                value: 'India',
                dropdownColor: AppColors.primaryDeepBlue,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(""),
                items: ['India', 'USA', 'UK', 'Canada', 'Australia'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  controller.nationalityController.text = val!;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
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

  Widget _genderPill(String gender) {
    bool isSelected = controller.profile.value.gender == gender;
    return GestureDetector(
      onTap: () => controller.updateGender(gender),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTeal : AppColors.primaryDeepBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          gender,
          style: TextStyle(
            color: isSelected ? AppColors.primaryDeepBlue : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
