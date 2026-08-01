import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'medical_info_view.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../controllers/profile_controller.dart';
import 'widgets/profile_form_shell.dart';

class PersonalInfoScreen extends StatefulWidget {
  final bool isFromLogin;
  const PersonalInfoScreen(BuildContext? context,
      {super.key, this.isFromLogin = false});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    if (controller.countryList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.getMasterCountryAPI(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileFormScaffold(
      title: 'Personal information',
      subtitle: 'Help doctors instantly know who you are',
      step: 1,
      heroIcon: Icons.person_rounded,
      bottomBar: Obx(
        () => ProfilePrimaryButton(
          text: widget.isFromLogin ? 'Save & continue' : 'Continue to medical',
          isLoading: controller.isLoading.value,
          onTap: _onContinue,
        ),
      ),
      children: [
        ProfileSectionCard(
          title: 'Profile photo',
          caption: 'Tap photo to upload from camera or gallery',
          icon: Icons.camera_alt_outlined,
          children: [
            Center(
              child: Obx(() {
                final file = controller.profileImage.value;
                final url = controller.profilePhotoUrl.value;
                final hasLocal = file != null;
                final hasNetwork = url.isNotEmpty &&
                    (url.startsWith('http://') || url.startsWith('https://'));

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => controller.showProfilePhotoSheet(context),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE8F5F1),
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.35),
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasLocal
                                ? Image.file(file, fit: BoxFit.cover)
                                : hasNetwork
                                    ? Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person_rounded,
                                          color: AppColors.teal,
                                          size: 48,
                                        ),
                                      )
                                    : const Icon(Icons.person_rounded,
                                        color: AppColors.teal, size: 48),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.tealDark,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () =>
                          controller.showProfilePhotoSheet(context),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(
                        hasLocal || hasNetwork
                            ? 'Change photo'
                            : 'Upload photo',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.tealDark,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
        ProfileSectionCard(
          title: 'Basic details',
          caption: 'Your legal name and contact',
          icon: Icons.badge_outlined,
          children: [
            CustomTextField(
              hint: 'Full Name',
              controller: controller.fullNameCtrl,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              hint: 'Email Address',
              controller: controller.emailCtrl,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              hint: 'Date of Birth',
              controller: controller.dobCtrl,
              prefixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate:
                      controller.selectedDob.value ?? DateTime(1990),
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.teal,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) {
                  controller.selectedDob.value = d;
                  controller.dobCtrl.text =
                      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
                }
              },
            ),
          ],
        ),
        ProfileSectionCard(
          title: 'Identity',
          caption: 'Gender and nationality',
          icon: Icons.public_rounded,
          accent: AppColors.orange,
          children: [
            Text(
              'Gender',
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.genders.map((g) {
                  return ProfileChoiceChip(
                    label: g,
                    selected: controller.selectedGender.value == g,
                    onTap: () => controller.selectedGender.value = g,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            Obx(() {
              if (controller.isCountryLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                );
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
                prefixIcon: Icons.flag_circle_outlined,
                onChanged: controller.onCountrySelected,
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _onContinue() {
    if (controller.fullNameCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter full name');
      return;
    }
    if (controller.emailCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter email');
      return;
    }
    if (controller.selectedDob.value == null) {
      Fluttertoast.showToast(msg: 'Please select date of birth');
      return;
    }
    if (controller.selectedGender.value.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select gender');
      return;
    }
    if (controller.selectedCountry.value == null) {
      Fluttertoast.showToast(msg: 'Please select nationality');
      return;
    }
    controller.updateProfileAPI(context, () {
      if (widget.isFromLogin) {
        Get.offAll(() => const DashboardScreen());
      } else {
        controller.getPatientProfileAPI(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicalInfoScreen(null)),
        );
      }
    });
  }
}
