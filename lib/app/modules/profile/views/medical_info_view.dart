import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'emergency_info_view.dart';
import '../controllers/profile_controller.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen(BuildContext? context, {super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  // PersonalInfo me Get.put() ho chuka hai, yaha same instance milega
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
          'Medical Info',
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
                value: 2 / 3,
                color: AppColors.teal,
                label: 'Step 2 of 3: Medical Info',
              ),
              const SizedBox(height: 12),
              Text(
                'This information helps in providing better care',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              McCard(
                isPremium: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vitals & Body', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    Obx(
                      () => McDropdown<String>(
                        hint: 'Blood Group',
                        value: controller.bloodGroup.value.isEmpty ? null : controller.bloodGroup.value,
                        items: controller.bloodGroups,
                        prefixIcon: Icons.bloodtype_outlined,
                        onChanged: (v) => controller.bloodGroup.value = v ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            hint: 'Height',
                            controller: controller.heightCtrl,
                            prefixIcon: Icons.height_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(
                          () => Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgNavy,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: ['cm', 'ft'].map((u) {
                                final sel = controller.heightUnit.value == u;
                                return GestureDetector(
                                  onTap: () => controller.heightUnit.value = u,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: sel ? AppColors.teal : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      u,
                                      style: AppTextStyles.captionBold.copyWith(
                                        color: sel ? Colors.white : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'Weight (kg)',
                      controller: controller.weightCtrl,
                      prefixIcon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
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
                    Text('Life Style', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    Obx(
                      () => McDropdown<String>(
                        hint: 'Marital Status',
                        value: controller.maritalStatus.value.isEmpty ? null : controller.maritalStatus.value,
                        items: controller.maritalStatusOptions,
                        prefixIcon: Icons.favorite_border_rounded,
                        onChanged: (v) => controller.maritalStatus.value = v ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => McDropdown<OccupationModel>(
                        hint: 'Occupation',
                        value: controller.selectedOccupationModel.value,
                        items: controller.occupationList,
                        itemLabel: (o) => o.name,
                        prefixIcon: Icons.work_outline_rounded,
                        onChanged: (v) {
                          controller.selectedOccupationModel.value = v;
                          if (v != null) {
                            controller.occupationCtrl.text = v.name;
                          }
                        },
                      ),
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
                    Text('Medical Background', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    Text('Known Allergies', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.allergyTags.map((a) {
                          final sel = controller.selectedAllergies.contains(a);
                          return GestureDetector(
                            onTap: () => controller.toggleAllergy(a),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.statusRed.withOpacity(0.1) : AppColors.bgNavy,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? AppColors.statusRed : AppColors.border,
                                ),
                              ),
                              child: Text(
                                (sel ? '✓ ' : '+ ') + a,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: sel ? AppColors.statusRed : AppColors.textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Current Medications', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            hint: 'e.g. Paracetamol',
                            controller: controller.medicationInputCtrl,
                            prefixIcon: Icons.medication_outlined,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: controller.addMedication,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.selectedMedications.map((m) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.teal.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m, style: AppTextStyles.captionBold.copyWith(color: AppColors.teal)),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => controller.removeMedication(m),
                                  child: const Icon(Icons.close_rounded, size: 14, color: AppColors.teal),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
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
                    Text('Health Status', style: AppTextStyles.heading3),
                    const SizedBox(height: 16),
                    Obx(
                      () => _ToggleRow(
                        label: 'Chronic Disease?',
                        value: controller.hasChronicDisease.value,
                        onChanged: (v) => controller.hasChronicDisease.value = v,
                        activeColor: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _ToggleRow(
                        label: 'Physically Handicapped?',
                        value: controller.isPhysicallyHandicapped.value,
                        onChanged: (v) => controller.isPhysicallyHandicapped.value = v,
                        activeColor: AppColors.orange,
                      ),
                    ),
                    Obx(
                      () => controller.isPhysicallyHandicapped.value
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: McDropdown<DisabilityTypeModel>(
                                hint: 'Disability Type',
                                value: controller.selectedDisabilityTypeModel.value,
                                items: controller.disabilityTypeList,
                                itemLabel: (d) => d.name,
                                prefixIcon: Icons.accessible_rounded,
                                onChanged: (v) {
                                  controller.selectedDisabilityTypeModel.value = v;
                                  if (v != null) {
                                    controller.disabilityTypeCtrl.text = v.name;
                                  }
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _ToggleRow(
                        label: 'Organ Donor',
                        value: controller.isOrganDonor.value,
                        onChanged: (v) => controller.isOrganDonor.value = v,
                        activeColor: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Obx(
                () => CustomPrimaryButton(
                  text: 'Continue →',
                  color: AppColors.teal,
                  isLoading: controller.isLoading.value,
                  onTap: () {
                    if (controller.bloodGroup.value.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select blood group");
                      return;
                    }
                    if (controller.heightCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter height");
                      return;
                    }
                    if (controller.weightCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter weight");
                      return;
                    }
                    if (controller.maritalStatus.value.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select marital status");
                      return;
                    }
                    if (controller.selectedOccupationModel.value == null) {
                      Fluttertoast.showToast(msg: "Please select occupation");
                      return;
                    }
                    if (controller.isPhysicallyHandicapped.value &&
                        controller.selectedDisabilityTypeModel.value == null &&
                        controller.disabilityTypeCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please select disability type");
                      return;
                    }
                    controller.updateMedicalAPI(context, () {
                      controller.getPatientProfileAPI(context); // Refresh data
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmergencyInfoScreen(null)),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding for switch
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.08) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: value ? AppColors.textTail : AppColors.textMuted,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }
}
