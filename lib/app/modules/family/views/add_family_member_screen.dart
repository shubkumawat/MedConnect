import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:healaura/app/core/Util/TextValidator/text_validation.dart';
import 'package:healaura/app/core/theme/app_colors.dart';
import 'package:healaura/app/core/theme/app_text_theme.dart';
import 'package:healaura/app/data/models/GetCountryApiResponseModel.dart'
    show CountryModel;

import '../../../core/Util/Print/print_log.dart';
import '../controllers/family_member_controller.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final controller = Get.find<FamilyMemberController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.countryList.isEmpty ||
          controller.relationList.isEmpty ||
          controller.occupationList.isEmpty ||
          controller.disabilityTypeList.isEmpty) {
        controller.getAllMasterDataAPI(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Obx(() {
        final isUpdate = controller.isUpdateMode.value;
        final loading = controller.isLoading.value &&
            isUpdate &&
            controller.familyMemberDetail.value == null;

        return Column(
          children: [
            _PremiumHeader(
              topPad: top,
              isUpdate: isUpdate,
              onBack: () => Get.back(),
            ),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      child: Column(
                        children: [
                          _PhotoHeroCard(
                            onTapPhoto: () => _showImageSourceSheet(context),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.04, end: 0),
                          const SizedBox(height: 14),
                          _SectionCard(
                            step: '01',
                            title: 'Personal information',
                            caption: 'Identity and basic details',
                            icon: Icons.badge_outlined,
                            children: [
                              CustomTextField(
                                hint: 'Full Name',
                                controller: controller.fullNameCtrl,
                                prefixIcon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.name,
                                inputFormatters: TxtValidation.nameFormatters,
                                validator: TxtValidation.personNameError,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'Mobile Number',
                                controller: controller.mobileNumberCtrl,
                                prefixIcon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                maxLength: TxtValidation.mobileMaxLength,
                                inputFormatters: TxtValidation.mobileFormatters,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'Health ID / ABHA Number (optional)',
                                controller: controller.abhaNumberCtrl,
                                prefixIcon: Icons.badge_outlined,
                                keyboardType: TextInputType.text,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'Date of Birth',
                                controller: controller.dobCtrl,
                                prefixIcon: Icons.calendar_month_outlined,
                                readOnly: true,
                                onTap: () => _pickDob(context),
                              ),
                              const SizedBox(height: 14),
                              const _FieldLabel('Gender'),
                              const SizedBox(height: 8),
                              Obx(
                                () => _ChoiceRow(
                                  items: controller.genders,
                                  selected: controller.selectedGender.value,
                                  onSelect: (v) =>
                                      controller.selectedGender.value = v,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(() {
                                if (controller.isRelationLoading.value) {
                                  return const _Loader();
                                }
                                return McDropdown(
                                  hint: 'Relation',
                                  value: controller
                                      .selectedRelationModel.value?.name,
                                  items: controller.relationList
                                      .map((r) => r.name)
                                      .toList(),
                                  prefixIcon: Icons.people_outline,
                                  onChanged: (v) {
                                    final index = controller.relationList
                                        .indexWhere((r) => r.name == v);
                                    if (index != -1) {
                                      controller.selectedRelationModel.value =
                                          controller.relationList[index];
                                    } else {
                                      PrintLog.printLog(
                                          'Relation match not found for: $v');
                                      controller.selectedRelationModel.value =
                                          null;
                                    }
                                  },
                                );
                              }),
                              const SizedBox(height: 12),
                              Obx(
                                () => McDropdown(
                                  hint: 'Marital Status',
                                  value: controller.maritalStatus.value.isEmpty
                                      ? null
                                      : controller.maritalStatus.value,
                                  items: controller.maritalStatusOptions,
                                  prefixIcon: Icons.favorite_outline,
                                  onChanged: (v) =>
                                      controller.maritalStatus.value = v ?? '',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(() {
                                if (controller.isOccupationLoading.value) {
                                  return const _Loader();
                                }
                                return McDropdown<OccupationModel>(
                                  hint: 'Occupation',
                                  value: controller
                                      .selectedOccupationModel.value,
                                  items: controller.occupationList,
                                  itemLabel: (o) => o.name,
                                  prefixIcon: Icons.work_outline_rounded,
                                  onChanged: (v) {
                                    controller.selectedOccupationModel.value =
                                        v;
                                    controller.occupationCtrl.text =
                                        v?.name ?? '';
                                  },
                                );
                              }),
                              const SizedBox(height: 12),
                              Obx(() {
                                if (controller.isCountryLoading.value) {
                                  return const _Loader();
                                }
                                return McDropdown<CountryModel>(
                                  hint: 'Nationality',
                                  value: controller.selectedCountry.value,
                                  items: controller.countryList,
                                  selectedItemBuilder: (c) => Text(
                                    '${c.flagEmoji}  ${c.name}',
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.textTail),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  itemLabel: (c) =>
                                      '${c.flagEmoji}  ${c.name}',
                                  prefixIcon: Icons.public,
                                  onChanged: (v) =>
                                      controller.selectedCountry.value = v,
                                );
                              }),
                            ],
                          ).animate().fadeIn(delay: 40.ms, duration: 300.ms),
                          const SizedBox(height: 12),
                          _SectionCard(
                            step: '02',
                            title: 'Medical profile',
                            caption: 'Vitals, allergies and conditions',
                            icon: Icons.medical_information_outlined,
                            accent: AppColors.orange,
                            children: [
                              Obx(
                                () => McDropdown(
                                  hint: 'Blood Group',
                                  value: controller.bloodGroup.value.isEmpty
                                      ? null
                                      : controller.bloodGroup.value,
                                  items: controller.bloodGroups,
                                  prefixIcon: Icons.water_drop_outlined,
                                  onChanged: (v) =>
                                      controller.bloodGroup.value = v ?? '',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      hint: 'Height (cm)',
                                      controller: controller.heightCtrl,
                                      prefixIcon: Icons.height,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomTextField(
                                      hint: 'Weight (kg)',
                                      controller: controller.weightCtrl,
                                      prefixIcon:
                                          Icons.monitor_weight_outlined,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const _FieldLabel('Allergies'),
                              const SizedBox(height: 8),
                              Obx(
                                () => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: controller.allergyTags.map((a) {
                                    final sel = controller.selectedAllergies
                                        .contains(a);
                                    return _TagChip(
                                      label: a,
                                      selected: sel,
                                      activeColor: AppColors.statusRed,
                                      onTap: () =>
                                          controller.toggleAllergy(a),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const _FieldLabel('Current medications'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      hint: 'e.g. Paracetamol',
                                      controller:
                                          controller.medicationInputCtrl,
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
                                        child: Icon(Icons.add_rounded,
                                            color: Colors.white),
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
                                  children: controller.selectedMedications
                                      .map(
                                        (m) => Chip(
                                          label: Text(m,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                          onDeleted: () =>
                                              controller.removeMedication(m),
                                          deleteIcon: const Icon(
                                              Icons.close_rounded,
                                              size: 14),
                                          backgroundColor:
                                              const Color(0xFFF3F7F5),
                                          side: BorderSide(
                                            color: AppColors.teal
                                                .withValues(alpha: 0.25),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ToggleTile(
                                label: 'Chronic disease',
                                value: controller.hasChronicDisease,
                                icon: Icons.warning_amber_rounded,
                                activeColor: AppColors.orange,
                              ),
                              const SizedBox(height: 8),
                              _ToggleTile(
                                label: 'Physically handicapped',
                                value: controller.isPhysicallyHandicapped,
                                icon: Icons.accessible_forward_rounded,
                                activeColor: AppColors.orange,
                              ),
                              Obx(
                                () => controller
                                        .isPhysicallyHandicapped.value
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10),
                                        child: controller
                                                .isDisabilityLoading.value
                                            ? const _Loader()
                                            : McDropdown<
                                                DisabilityTypeModel>(
                                                hint: 'Disability Type',
                                                value: controller
                                                    .selectedDisabilityTypeModel
                                                    .value,
                                                items: controller
                                                    .disabilityTypeList,
                                                itemLabel: (d) => d.name,
                                                prefixIcon:
                                                    Icons.info_outline,
                                                onChanged: (v) {
                                                  controller
                                                      .selectedDisabilityTypeModel
                                                      .value = v;
                                                  controller.disabilityTypeCtrl
                                                      .text = v?.name ?? '';
                                                },
                                              ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 8),
                              _ToggleTile(
                                label: 'Organ donor',
                                value: controller.isOrganDonor,
                                icon: Icons.favorite_rounded,
                                activeColor: AppColors.statusRed,
                              ),
                            ],
                          ).animate().fadeIn(delay: 70.ms, duration: 300.ms),
                          const SizedBox(height: 12),
                          _SectionCard(
                            step: '03',
                            title: 'Address & insurance',
                            caption: 'Location and coverage details',
                            icon: Icons.home_work_outlined,
                            accent: AppColors.accentBlue,
                            children: [
                              CustomTextField(
                                hint: 'Address / Area',
                                controller: controller.addressLineCtrl,
                                prefixIcon: Icons.home_outlined,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'City',
                                controller: controller.cityCtrl,
                                prefixIcon: Icons.location_city_rounded,
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => McDropdown(
                                  hint: 'State',
                                  value:
                                      controller.selectedState.value.isEmpty
                                          ? null
                                          : controller.selectedState.value,
                                  items: controller.states,
                                  prefixIcon: Icons.map_outlined,
                                  onChanged: (v) => controller
                                      .selectedState.value = v ?? '',
                                ),
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'PIN / Post code',
                                controller: controller.postCodeCtrl,
                                prefixIcon: Icons.pin_drop_outlined,
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'Insurance Provider',
                                controller:
                                    controller.insuranceProviderCtrl,
                                prefixIcon: Icons.security_rounded,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'Policy Number',
                                controller: controller.policyNumberCtrl,
                                prefixIcon: Icons.numbers_rounded,
                              ),
                            ],
                          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                          const SizedBox(height: 12),
                          _SectionCard(
                            step: '04',
                            title: 'Emergency contact',
                            caption: 'Shown when every second counts',
                            icon: Icons.sos_outlined,
                            accent: AppColors.statusRed,
                            children: [
                              CustomTextField(
                                hint: 'Contact Person Name',
                                controller: controller.contactNameCtrl,
                                prefixIcon: Icons.person_pin_outlined,
                                keyboardType: TextInputType.name,
                                inputFormatters: TxtValidation.nameFormatters,
                                validator: TxtValidation.personNameError,
                              ),
                              const SizedBox(height: 12),
                              CustomTextField(
                                hint: 'Mobile Number',
                                controller: controller.contactMobileCtrl,
                                prefixIcon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                maxLength: TxtValidation.mobileMaxLength,
                                inputFormatters: TxtValidation.mobileFormatters,
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => McDropdown(
                                  hint: 'Relationship',
                                  value: controller
                                          .contactRelation.value.isEmpty
                                      ? null
                                      : controller.contactRelation.value,
                                  items: controller.contactRelations,
                                  prefixIcon: Icons.link_rounded,
                                  onChanged: (v) => controller
                                      .contactRelation.value = v ?? '',
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 130.ms, duration: 300.ms),
                        ],
                      ),
                    ),
            ),
            if (!loading)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () =>
                                controller.submitFamilyMember(context, () {
                                  Navigator.pop(context, true);
                                }),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.tealDark,
                          disabledBackgroundColor:
                              AppColors.tealDark.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isUpdate
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.person_add_alt_1_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isUpdate
                                        ? 'Update member profile'
                                        : 'Create member profile',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _pickDob(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: controller.selectedDob.value ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) {
      controller.selectedDob.value = d;
      controller.dobCtrl.text = DateFormat('dd / MM / yyyy').format(d);
    }
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.teal),
                ),
                title: const Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImage(ImageSource.camera,);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.teal),
                ),
                title: const Text('Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600,color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final double topPad;
  final bool isUpdate;
  final VoidCallback onBack;

  const _PremiumHeader({
    required this.topPad,
    required this.isUpdate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo/ic_logo_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUpdate ? 'Update Member' : 'Add Member',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isUpdate
                          ? 'Edit family health profile'
                          : 'Create family health profile',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: const [
                _HeaderChip(label: 'Personal'),
                _Dot(),
                _HeaderChip(label: 'Medical'),
                _Dot(),
                _HeaderChip(label: 'Address'),
                _Dot(),
                _HeaderChip(label: 'Emergency', last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final bool last;
  const _HeaderChip({required this.label, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Teal cover + full circular photo (Stack, never clipped).
class _PhotoHeroCard extends StatelessWidget {
  final VoidCallback onTapPhoto;
  const _PhotoHeroCard({required this.onTapPhoto});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FamilyMemberController>();
    const coverH = 96.0;
    const avatarSize = 78.0;

    return Obx(() {
      final file = controller.profileImage.value;
      final url = controller.familyMemberDetail.value?.profilePhoto;
      final name = controller.fullNameCtrl.text.trim();
      final initials = name.isEmpty
          ? '?'
          : name
              .split(RegExp(r'\s+'))
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join();

      final avatar = GestureDetector(
        onTap: onTapPhoto,
        child: Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.teal.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: file != null
                      ? Image.file(file, fit: BoxFit.cover)
                      : (url != null && url.isNotEmpty)
                          ? Image.network(url, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.tealDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.tealDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
            ],
          ),
        ),
      );

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.65)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: coverH,
                    width: double.infinity,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0A5C45),
                            Color(0xFF147A68),
                            Color(0xFF1B9E8E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, avatarSize / 2 + 12, 16, 16),
                  child: Column(
                    children: [
                      Text(
                        'Profile photo',
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the photo to upload from camera or gallery',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: coverH - avatarSize / 2,
            left: 0,
            right: 0,
            child: Center(child: avatar),
          ),
        ],
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  final String step;
  final String title;
  final String caption;
  final IconData icon;
  final Color accent;
  final List<Widget> children;

  const _SectionCard({
    required this.step,
    required this.title,
    required this.caption,
    required this.icon,
    required this.children,
    this.accent = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ChoiceRow({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final sel = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppColors.tealDark : const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: sel
                    ? Colors.transparent
                    : AppColors.border.withValues(alpha: 0.9),
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: sel ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.1)
              : const Color(0xFFF3F7F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.35)
                : AppColors.border.withValues(alpha: 0.9),
          ),
        ),
        child: Text(
          selected ? '✓  $label' : '+  $label',
          style: TextStyle(
            color: selected ? activeColor : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final RxBool value;
  final IconData icon;
  final Color activeColor;

  const _ToggleTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: value.value
              ? activeColor.withValues(alpha: 0.08)
              : const Color(0xFFF3F7F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value.value
                ? activeColor.withValues(alpha: 0.3)
                : const Color(0xFFE3EBE7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value.value ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color:
                      value.value ? AppColors.textDark : AppColors.textMuted,
                ),
              ),
            ),
            Switch.adaptive(
              value: value.value,
              onChanged: (v) => value.value = v,
              activeTrackColor: activeColor,
              activeThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: LinearProgressIndicator(
        color: AppColors.teal,
        backgroundColor: Color(0xFFE8F2EE),
      ),
    );
  }
}
