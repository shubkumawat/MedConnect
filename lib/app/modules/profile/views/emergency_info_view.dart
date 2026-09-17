import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:healaura/app/core/Util/TextValidator/text_validation.dart';
import 'package:healaura/app/data/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../controllers/profile_controller.dart';
import 'widgets/profile_form_shell.dart';
import 'package:healaura/app/core/Util/app_toast.dart';
import '../../../core/Util/CustomLoading/custom_loading.dart';

class EmergencyInfoScreen extends StatefulWidget {
  final bool isFromLogin;

  const EmergencyInfoScreen(
    BuildContext? context, {
    super.key,
    this.isFromLogin = false,
  });

  @override
  State<EmergencyInfoScreen> createState() => _EmergencyInfoScreenState();
}

class _EmergencyInfoScreenState extends State<EmergencyInfoScreen> {
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomLoading().forceHide();
      if (controller.relationList.isEmpty) {
        controller.getMasterRelationAPI(context);
      }
    });
  }

  Future<void> _finishOnboardingLogin() async {
    final storage = StorageService();
    await storage.setBool(StorageService.isLogin, true);
    await storage.setBool(StorageService.profileSetupDone, true);
  }

  Future<void> _goToDashboard() async {
    if (widget.isFromLogin) {
      await _finishOnboardingLogin();
    }
    Get.offAll(
      () => const DashboardScreen(),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFormScaffold(
      title: 'Emergency information',
      subtitle: 'Shown via QR when every second counts',
      step: 3,
      heroIcon: Icons.emergency_rounded,
      bottomBar: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfilePrimaryButton(
              text: widget.isFromLogin ? 'Complete setup' : 'Save',
              color: AppColors.tealDark,
              isLoading: controller.isSaving.value,
              onTap: _onComplete,
            ),
            if (widget.isFromLogin) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: controller.isSaving.value ? null : _goToDashboard,
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
          title: 'Emergency contact',
          caption: 'Visible on your health QR in emergencies',
          icon: Icons.sos_rounded,
          accent: AppColors.statusRed,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.statusRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.statusRed.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.statusRed.withValues(alpha: 0.9),
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep this updated so responders can reach your family fast.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomTextField(
              hint: 'Contact Name',
              controller: controller.emergencyNameCtrl,
              prefixIcon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              inputFormatters: TxtValidation.nameFormatters,
              validator: TxtValidation.personNameError,
            ),
            const SizedBox(height: 14),
            Obx(
              () => McDropdown<String>(
                hint: 'Relationship',
                value: controller.emergencyRelation.value.isEmpty
                    ? null
                    : controller.emergencyRelation.value,
                items: controller.emergencyRelations,
                prefixIcon: Icons.link_rounded,
                onChanged: (v) {
                  controller.emergencyRelation.value = v ?? '';
                  if (v == null) {
                    controller.selectedEmergencyRelationModel.value = null;
                  } else {
                    controller.selectedEmergencyRelationModel.value =
                        controller.relationList.firstWhereOrNull(
                      (r) =>
                          r.name.toLowerCase() == v.toLowerCase() ||
                          r.code.toLowerCase() == v.toLowerCase(),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              hint: 'Mobile Number',
              controller: controller.emergencyMobileCtrl,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: TxtValidation.mobileMaxLength,
              inputFormatters: TxtValidation.mobileFormatters,
            ),
          ],
        ),
        ProfileSectionCard(
          title: 'Location',
          caption: 'Home address for emergency responders',
          icon: Icons.location_on_outlined,
          accent: AppColors.accentBlue,
          children: [
            CustomTextField(
              hint: 'Address / Area',
              controller: controller.addressLineCtrl,
              prefixIcon: Icons.home_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              hint: 'Home City',
              controller: controller.cityCtrl,
              prefixIcon: Icons.location_city_rounded,
            ),
            const SizedBox(height: 14),
            Obx(
              () => McDropdown<String>(
                hint: 'State',
                value: controller.selectedState.value.isEmpty
                    ? null
                    : controller.selectedState.value,
                items: controller.states,
                prefixIcon: Icons.map_outlined,
                onChanged: (v) => controller.selectedState.value = v ?? '',
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              hint: 'PIN / Post code',
              controller: controller.postCodeCtrl,
              prefixIcon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        Obx(
          () => ProfileSectionCard(
            title: 'Insurance',
            caption: controller.showInsurance.value
                ? 'Optional coverage details'
                : 'Tap to add optional insurance',
            icon: Icons.health_and_safety_outlined,
            children: [
              Material(
                color: const Color(0xFFF3F7F5),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => controller.showInsurance.value =
                      !controller.showInsurance.value,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          controller.showInsurance.value
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.showInsurance.value
                              ? 'Hide insurance fields'
                              : 'Add insurance details',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.tealDark,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (controller.showInsurance.value) ...[
                const SizedBox(height: 14),
                CustomTextField(
                  hint: 'Insurance Provider',
                  controller: controller.insuranceProviderCtrl,
                  prefixIcon: Icons.article_outlined,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  hint: 'Policy Number',
                  controller: controller.policyNumberCtrl,
                  prefixIcon: Icons.numbers_outlined,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _onComplete() {
    final nameErr =
        TxtValidation.personNameError(controller.emergencyNameCtrl.text);
    if (nameErr != null) {
      AppToast.showToast(msg: nameErr);
      return;
    }
    if (controller.selectedEmergencyRelationModel.value == null &&
        controller.emergencyRelation.value.isEmpty) {
      AppToast.showToast(msg: 'Please select relationship');
      return;
    }
    final mobileErr =
        TxtValidation.mobileError(controller.emergencyMobileCtrl.text);
    if (mobileErr != null) {
      AppToast.showToast(msg: mobileErr);
      return;
    }
    if (controller.cityCtrl.text.trim().isEmpty) {
      AppToast.showToast(msg: 'Please enter city');
      return;
    }
    if (controller.selectedState.value.isEmpty) {
      AppToast.showToast(msg: 'Please select state');
      return;
    }
    controller.updateEmergencyAPI(context, () {
      if (widget.isFromLogin) {
        _goToDashboard();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        _goToDashboard();
      }
    });
  }
}
