import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../controllers/profile_controller.dart';

class EmergencyInfoScreen extends StatefulWidget {
  const EmergencyInfoScreen(BuildContext? context, {super.key});

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  // PersonalInfo me Get.put() ho chuka hai, yaha same instance milega
  // ProfileController controller = Get.put(ProfileController());
  final ProfileController controller = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.tealDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              McProgressBar(
                value: 1.0,
                color: AppColors.green,
                label: 'Step 3 of 3: Emergency Info',
              ),
              const SizedBox(height: 12),
              Text(
                'Essential for your safety during medical emergencies',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              McCard(
                isPremium: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.statusRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sos_rounded, color: AppColors.statusRed, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Emergency Contact', style: AppTextStyles.heading3),
                              Text('Shown via QR scan in emergencies', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      hint: 'Contact Name',
                      controller: controller.emergencyNameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    Obx(() => McDropdown<String>(
                        hint: 'Relationship',
                        value: controller.emergencyRelation.value.isEmpty ? null : controller.emergencyRelation.value,
                        items: controller.emergencyRelations,
                        prefixIcon: Icons.link_rounded,
                        onChanged: (v) {
                          controller.emergencyRelation.value = v ?? '';
                          if (v != null) {
                            // Sync with model if exists for API code
                            controller.selectedEmergencyRelationModel.value = controller.relationList.firstWhereOrNull(
                                  (r) => r.name.toLowerCase() == v.toLowerCase() || 
                                         r.code.toLowerCase() == v.toLowerCase(),
                            );
                          }
                        },
                    )),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'Mobile Number',
                      controller: controller.emergencyMobileCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              McCard(
                isPremium: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location Details', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hint: 'Home City',
                      controller: controller.cityCtrl,
                      prefixIcon: Icons.location_city_rounded,
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => McDropdown<String>(
                        hint: 'State',
                        value: controller.selectedState.value.isEmpty ? null : controller.selectedState.value,
                        items: controller.states,
                        prefixIcon: Icons.map_outlined,
                        onChanged: (v) => controller.selectedState.value = v ?? '',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Insurance collapsible
              Obx(
                () => GestureDetector(
                  onTap: () => controller.showInsurance.value = !controller.showInsurance.value,
                  child: McCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.health_and_safety_rounded, color: AppColors.accentTeal, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Insurance Details (Optional)',
                            style: AppTextStyles.body.copyWith(color: AppColors.textTail),
                          ),
                        ),
                        Icon(
                          controller.showInsurance.value ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Obx(
                () => controller.showInsurance.value
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: McCard(
                          isPremium: true,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              CustomTextField(
                                hint: 'Insurance Provider',
                                controller: controller.insuranceProviderCtrl,
                                prefixIcon: Icons.article_outlined,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                hint: 'Policy Number',
                                controller: controller.policyNumberCtrl,
                                prefixIcon: Icons.numbers_outlined,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 40),

              Obx(
                () => CustomPrimaryButton(
                  text: 'Complete Setup ✓',
                  color: AppColors.green,
                  isLoading: controller.isLoading.value,
                  onTap: () {
                    if (controller.emergencyNameCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter emergency contact name");
                      return;
                    }
                    if (controller.selectedEmergencyRelationModel.value == null && controller.emergencyRelation.value.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select relationship");
                      return;
                    }
                    if (controller.emergencyMobileCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter mobile number");
                      return;
                    }
                    if (controller.cityCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter city");
                      return;
                    }
                    if (controller.selectedState.value.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select state");
                      return;
                    }
                    controller.updateEmergencyAPI(context, () {
                      controller.getPatientProfileAPI(context); 
                      int count = 0;
                      Navigator.popUntil(context, (route) => count++ == 3);
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Center(
              //   child: TextButton(
              //     onTap: () {
              //       Get.delete<ProfileController>();
              //       Navigator.pushAndRemoveUntil(
              //         context,
              //         MaterialPageRoute(builder: (_) => const HomeScreen()),
              //         (_) => false,
              //       );
              //     },
              //     child: Text(
              //       'Skip for now',
              //       style: AppTextStyles.caption.copyWith(
              //         color: AppColors.textMuted,
              //         decoration: TextDecoration.underline,
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
