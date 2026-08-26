import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'emergency_info_view.dart';
import '../controllers/profile_controller.dart';
import 'widgets/profile_form_shell.dart';

class MedicalInfoScreen extends StatefulWidget {
  final bool isFromLogin;

  const MedicalInfoScreen(
    BuildContext? context, {
    super.key,
    this.isFromLogin = false,
  });

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.occupationList.isEmpty) {
        controller.getMasterOccupationAPI(context);
      }
      if (controller.disabilityTypeList.isEmpty) {
        controller.getMasterDisabilityTypeAPI(context);
      }
    });
  }

  void _goToEmergency() {
    if (widget.isFromLogin) {
      Get.to(
        () => const EmergencyInfoScreen(null, isFromLogin: true),
        transition: Transition.rightToLeft,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyInfoScreen(null)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFormScaffold(
      title: 'Medical information',
      subtitle: 'Vitals and history for better care',
      step: 2,
      heroIcon: Icons.medical_services_rounded,
      bottomBar: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfilePrimaryButton(
              text: 'Continue to emergency',
              isLoading: controller.isLoading.value,
              onTap: _onContinue,
            ),
            if (widget.isFromLogin) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: controller.isLoading.value ? null : _goToEmergency,
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      children: [
        ProfileSectionCard(
          title: 'Vitals & body',
          caption: 'Blood group, height and weight',
          icon: Icons.monitor_heart_outlined,
          children: [
            Obx(
              () => McDropdown<String>(
                hint: 'Blood Group',
                value: controller.bloodGroup.value.isEmpty
                    ? null
                    : controller.bloodGroup.value,
                items: controller.bloodGroups,
                prefixIcon: Icons.bloodtype_outlined,
                onChanged: (v) => controller.bloodGroup.value = v ?? '',
              ),
            ),
            const SizedBox(height: 14),
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
                const SizedBox(width: 10),
                Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Row(
                      children: ['cm', 'ft'].map((u) {
                        final sel = controller.heightUnit.value == u;
                        return GestureDetector(
                          onTap: () => controller.heightUnit.value = u,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.tealDark : Colors.transparent,
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
            const SizedBox(height: 14),
            CustomTextField(
              hint: 'Weight (kg)',
              controller: controller.weightCtrl,
              prefixIcon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        ProfileSectionCard(
          title: 'Lifestyle',
          caption: 'Helps personalize recommendations',
          icon: Icons.favorite_border_rounded,
          accent: AppColors.orange,
          children: [
            Obx(
              () => McDropdown<String>(
                hint: 'Marital Status',
                value: controller.maritalStatus.value.isEmpty
                    ? null
                    : controller.maritalStatus.value,
                items: controller.maritalStatusOptions,
                prefixIcon: Icons.favorite_border_rounded,
                onChanged: (v) => controller.maritalStatus.value = v ?? '',
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => McDropdown<OccupationModel>(
                hint: 'Occupation',
                value: controller.selectedOccupationModel.value,
                items: controller.occupationList,
                itemLabel: (o) => o.name,
                prefixIcon: Icons.work_outline_rounded,
                onChanged: (v) {
                  controller.selectedOccupationModel.value = v;
                  controller.occupationCtrl.text = v?.name ?? '';
                },
              ),
            ),
          ],
        ),
        ProfileSectionCard(
          title: 'Medical background',
          caption: 'Allergies and current medicines',
          icon: Icons.medical_information_outlined,
          accent: AppColors.statusRed,
          children: [
            Text(
              'Known allergies',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.allergyTags.map((a) {
                  final sel = controller.selectedAllergies.contains(a);
                  return ProfileChoiceChip(
                    label: (sel ? '✓  ' : '+  ') + a,
                    selected: sel,
                    activeColor: AppColors.statusRed,
                    onTap: () => controller.toggleAllergy(a),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Current medications',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
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
                Material(
                  color: AppColors.tealDark,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: controller.addMedication,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.selectedMedications.map((m) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m,
                          style: AppTextStyles.captionBold
                              .copyWith(color: AppColors.tealDark),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => controller.removeMedication(m),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: AppColors.teal),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        ProfileSectionCard(
          title: 'Health status',
          caption: 'Chronic conditions and preferences',
          icon: Icons.health_and_safety_outlined,
          children: [
            Obx(
              () => _StatusToggle(
                label: 'Chronic disease?',
                value: controller.hasChronicDisease.value,
                onChanged: (v) => controller.hasChronicDisease.value = v,
                activeColor: AppColors.orange,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => _StatusToggle(
                label: 'Physically handicapped?',
                value: controller.isPhysicallyHandicapped.value,
                onChanged: (v) => controller.isPhysicallyHandicapped.value = v,
                activeColor: AppColors.orange,
              ),
            ),
            Obx(
              () => controller.isPhysicallyHandicapped.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: McDropdown<DisabilityTypeModel>(
                        hint: 'Disability Type',
                        value: controller.selectedDisabilityTypeModel.value,
                        items: controller.disabilityTypeList,
                        itemLabel: (d) => d.name,
                        prefixIcon: Icons.accessible_rounded,
                        onChanged: (v) {
                          controller.selectedDisabilityTypeModel.value = v;
                          controller.disabilityTypeCtrl.text = v?.name ?? '';
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            Obx(
              () => _StatusToggle(
                label: 'Organ donor',
                value: controller.isOrganDonor.value,
                onChanged: (v) => controller.isOrganDonor.value = v,
                activeColor: AppColors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _onContinue() {
    if (controller.bloodGroup.value.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select blood group');
      return;
    }
    if (controller.heightCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter height');
      return;
    }
    if (controller.weightCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter weight');
      return;
    }
    if (controller.maritalStatus.value.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select marital status');
      return;
    }
    if (controller.selectedOccupationModel.value == null) {
      Fluttertoast.showToast(msg: 'Please select occupation');
      return;
    }
    if (controller.isPhysicallyHandicapped.value &&
        controller.selectedDisabilityTypeModel.value == null &&
        controller.disabilityTypeCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please select disability type');
      return;
    }
    controller.updateMedicalAPI(context, () {
      controller.getPatientProfileAPI(context);
      _goToEmergency();
    });
  }
}

class _StatusToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const _StatusToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withValues(alpha: 0.08)
            : const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: value ? AppColors.textDark : AppColors.textMuted,
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
