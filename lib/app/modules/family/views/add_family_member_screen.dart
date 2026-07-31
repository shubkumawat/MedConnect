import 'dart:io';

import 'package:healaura/app/data/models/GetCountryApiResponseModel.dart' show CountryModel;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/Util/Print/print_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';

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
      if (controller.countryList.isEmpty || controller.relationList.isEmpty || controller.occupationList.isEmpty || controller.disabilityTypeList.isEmpty) {
        controller.getAllMasterDataAPI(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: controller.isUpdateMode.value ? 'Update Family Member' : 'Add Family Member',
        showBack: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.isUpdateMode.value && controller.familyMemberDetail.value == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Premium Photo Picker ---
                Center(
                  child: Stack(
                    children: [
                      Obx(() => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.teal.withOpacity(0.3), width: 3),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: controller.profileImage.value != null
                              ? Image.file(controller.profileImage.value!, fit: BoxFit.cover)
                              : (controller.familyMemberDetail.value?.profilePhoto != null
                                  ? Image.network(controller.familyMemberDetail.value!.profilePhoto!, fit: BoxFit.cover)
                                  : Icon(Icons.person_rounded, size: 55, color: AppColors.teal.withOpacity(0.6))),
                        ),
                      )),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _showImageSourceSheet(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ==================== Personal Information ====================
                _buildSectionHeader('Personal Information', Icons.person_rounded, AppColors.black),
                const SizedBox(height: 16),
                McCard(
                  color: Colors.white,
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        hint: 'Full Name',
                        controller: controller.fullNameCtrl,
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hint: 'Mobile Number',
                        controller: controller.mobileNumberCtrl,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hint: 'Date of Birth',
                        controller: controller.dobCtrl,
                        prefixIcon: Icons.calendar_month_outlined,
                        maxLength: 15,
                        readOnly: true,
                        onTap: () async {
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
                                  onSurface: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (d != null) {
                            controller.selectedDob.value = d;
                            controller.dobCtrl.text = DateFormat('dd / MM / yyyy').format(d);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Gender'),
                      const SizedBox(height: 10),
                      Obx(() => _buildChipSelector(
                        items: controller.genders,
                        selectedItem: controller.selectedGender.value,
                        onSelect: (v) => controller.selectedGender.value = v,
                      )),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isRelationLoading.value) {
                          return const LinearProgressIndicator(
                            color: AppColors.teal,
                            backgroundColor: AppColors.bgCardNavy,
                          );
                        }
                        return McDropdown(
                          hint: 'Relation',
                          value: controller.selectedRelationModel.value?.name,
                          items: controller.relationList.map((r) => r.name).toList(),
                          prefixIcon: Icons.people_outline,
                          onChanged: (v) {
                            // name ke bajaye index se match karo — duplicate/whitespace names me bhi safe
                            final index = controller.relationList.indexWhere((r) => r.name == v);
                            if (index != -1) {
                              controller.selectedRelationModel.value = controller.relationList[index];
                            } else {
                              PrintLog.printLog('Relation match not found for value: $v');
                              controller.selectedRelationModel.value = null;
                            }
                          },
                        );
                      }),                      const SizedBox(height: 16),
                      Obx(() => McDropdown(
                        hint: 'Marital Status',
                        value: controller.maritalStatus.value.isEmpty ? null : controller.maritalStatus.value,
                        items: controller.maritalStatusOptions,
                        prefixIcon: Icons.favorite_outline,
                        onChanged: (v) => controller.maritalStatus.value = v ?? '',
                      )),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isOccupationLoading.value) {
                          return const LinearProgressIndicator(
                            color: AppColors.teal,
                            backgroundColor: AppColors.bgCardNavy,
                          );
                        }
                        return McDropdown<OccupationModel>(
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
                        );
                      }),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isCountryLoading.value) {
                          return const LinearProgressIndicator(color: AppColors.teal, backgroundColor: AppColors.bgCardNavy);
                        }
                        return McDropdown<CountryModel>(
                          hint: 'Nationality',
                          value: controller.selectedCountry.value,
                          items: controller.countryList,
                          selectedItemBuilder: (c) => Text(
                            '${c.flagEmoji}  ${c.name}',
                            style: AppTextStyles.body.copyWith(color: AppColors.textTail),
                            overflow: TextOverflow.ellipsis,
                          ),
                          itemLabel: (c) => '${c.flagEmoji}  ${c.name}',
                          prefixIcon: Icons.public,
                          onChanged: (v) {
                            controller.selectedCountry.value = v;
                          },
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== Medical Information ====================
                _buildSectionHeader('Medical Profile', Icons.health_and_safety_rounded, AppColors.orange),
                const SizedBox(height: 16),
                McCard(
                  color: Colors.white,
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => McDropdown(
                        hint: 'Blood Group',
                        value: controller.bloodGroup.value.isEmpty ? null : controller.bloodGroup.value,
                        items: controller.bloodGroups,
                        prefixIcon: Icons.water_drop_outlined,
                        onChanged: (v) => controller.bloodGroup.value = v ?? '',
                      )),
                      const SizedBox(height: 16),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              hint: 'Weight (kg)',
                              controller: controller.weightCtrl,
                              prefixIcon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Allergies (If any)'),
                      const SizedBox(height: 10),
                      Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.allergyTags.map((a) {
                          final sel = controller.selectedAllergies.contains(a);
                          return ChoiceChip(
                            label: Text(a),
                            selected: sel,
                            onSelected: (_) => controller.toggleAllergy(a),
                            selectedColor: AppColors.statusRed.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: sel ? AppColors.statusRed : AppColors.textMuted,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            backgroundColor: AppColors.bgCardNavy.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: BorderSide(
                              color: sel ? AppColors.statusRed : AppColors.teal,
                              width: 1.2,
                            ),
                          );
                        }).toList(),
                      )),
                      const SizedBox(height: 24),
                      _buildLabel('Current Medications'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              hint: 'Enter Medication Name',
                              controller: controller.medicationInputCtrl,
                              prefixIcon: Icons.medication_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: controller.addMedication,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: controller.selectedMedications.map((m) => Chip(
                          label: Text(m, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => controller.removeMedication(m),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          backgroundColor: AppColors.bgCardNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        )).toList(),
                      )),
                      const SizedBox(height: 24),
                      _buildPremiumToggle(
                        label: 'Chronic Disease',
                        value: controller.hasChronicDisease,
                        icon: Icons.warning_amber_rounded,
                        activeColor: AppColors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildPremiumToggle(
                        label: 'Physically Handicapped',
                        value: controller.isPhysicallyHandicapped,
                        icon: Icons.accessible_forward_rounded,
                        activeColor: AppColors.orange,
                      ),
                      Obx(() => controller.isPhysicallyHandicapped.value
                          ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: controller.isDisabilityLoading.value
                            ? const LinearProgressIndicator(color: AppColors.teal, backgroundColor: AppColors.bgCardNavy)
                            : McDropdown<DisabilityTypeModel>(
                          hint: 'Disability Type',
                          value: controller.selectedDisabilityTypeModel.value,
                          items: controller.disabilityTypeList,
                          itemLabel: (d) => d.name,
                          prefixIcon: Icons.info_outline,
                          onChanged: (v) {
                            controller.selectedDisabilityTypeModel.value = v;
                            if (v != null) {
                              controller.disabilityTypeCtrl.text = v.name;
                            }
                          },
                        ),
                      )
                          : const SizedBox.shrink()),
                      const SizedBox(height: 12),
                      _buildPremiumToggle(
                        label: 'Organ Donor',
                        value: controller.isOrganDonor,
                        icon: Icons.favorite_rounded,
                        activeColor: AppColors.statusRed,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== Address & Insurance ====================
                _buildSectionHeader('Address & Insurance', Icons.home_work_rounded, AppColors.navHome),
                const SizedBox(height: 16),
                McCard(
                  color: Colors.white,
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              hint: 'City',
                              controller: controller.cityCtrl,
                              prefixIcon: Icons.location_city,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Obx(
                                () => McDropdown(
                                  hint: 'State',
                                  value: controller.selectedState.value.isEmpty
                                      ? null
                                      : controller.selectedState.value,
                                  items: controller.states,
                                  onChanged: (v) => controller.selectedState.value = v ?? '',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hint: 'Insurance Provider',
                        controller: controller.insuranceProviderCtrl,
                        prefixIcon: Icons.security_rounded,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hint: 'Policy Number',
                        controller: controller.policyNumberCtrl,
                        prefixIcon: Icons.numbers_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ==================== Emergency Contact ====================
                _buildSectionHeader('Emergency Contact', Icons.emergency_rounded, AppColors.statusRed),
                const SizedBox(height: 16),
                McCard(
                  color: Colors.white,
                  borderRadius: 20,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CustomTextField(
                        hint: 'Contact Person Name',
                        controller: controller.contactNameCtrl,
                        prefixIcon: Icons.person_pin_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        hint: 'Mobile Number',
                        controller: controller.contactMobileCtrl,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Obx(() {
                      //   if (controller.isRelationLoading.value) {
                      //     return const LinearProgressIndicator(
                      //       color: AppColors.teal,
                      //       backgroundColor: AppColors.bgCardNavy,
                      //     );
                      //   }
                      //
                      //   return McDropdown(
                      //     hint: 'Relation',
                      //     value: controller.contactRelation.value,
                      //     items: controller.relationList.map((r) => r.name).toList(),
                      //     prefixIcon: Icons.people_outline,
                      //     onChanged: (v) {
                      //       final index = controller.relationList.indexWhere((r) => r.name == v);
                      //
                      //       if (index != -1) {
                      //         // Dropdown me selected name
                      //         controller.contactRelation.value =
                      //             controller.relationList[index].name ?? "";
                      //
                      //         // Alag variable me relation code
                      //         controller.contactRelation.value =
                      //             controller.relationList[index].code ?? "";
                      //       } else {
                      //         PrintLog.printLog('Relation match not found for value: $v');
                      //         controller.contactRelation.value = "";
                      //         controller.contactRelation.value = "";
                      //       }
                      //     },
                      //   );
                      // })
                      Obx(() => McDropdown(
                        hint: 'Relationship',
                        value: controller.contactRelation.value.isEmpty ? null : controller.contactRelation.value,
                        items: controller.contactRelations,
                        prefixIcon: Icons.link_rounded,
                        onChanged: (v) => controller.contactRelation.value = v ?? '',
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                Obx(() => CustomPrimaryButton(
                  text: controller.isUpdateMode.value ? 'Update Member Profile' : 'Create Member Profile',
                  isLoading: controller.isLoading.value,
                  onTap: () => controller.submitFamilyMember(context, () {
                    Navigator.pop(context, true);
                  }),
                )),
                const SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.black, fontWeight: FontWeight.w600));
  }

  Widget _buildChipSelector({required List<String> items, required String selectedItem, required Function(String) onSelect}) {
    return Wrap(
      spacing: 10,
      children: items.map((item) {
        final isSelected = selectedItem == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.teal : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.teal : AppColors.teal),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
            ),
            child: Text(
              item,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPremiumToggle({required String label, required RxBool value, required IconData icon, required Color activeColor}) {
    return Obx(() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCardNavy.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: value.value ? activeColor.withOpacity(0.5) : Colors.teal),
      ),
      child: Row(
        children: [
          Icon(icon, color: value.value ? activeColor : AppColors.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 14))),
          Switch.adaptive(
            value: value.value,
            onChanged: (v) => value.value = v,
            activeColor: activeColor,
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.textMuted.withOpacity(0.4),
          ),
        ],
      ),
    ));
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCardNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Photo Source', style: AppTextStyles.heading3),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.teal),
                title: Text('Camera', style: AppTextStyles.body),
                onTap: () {
                  Navigator.pop(context);
                  controller.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.teal),
                title: Text('Gallery', style: AppTextStyles.body),
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
