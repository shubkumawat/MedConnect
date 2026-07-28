import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'medical_info_view.dart';
import '../controllers/profile_controller.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen(BuildContext? context, {super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Yaha se poora flow shuru hota hai isliye controller yaha put ho raha hai.
  // MedicalInfo/EmergencyInfo Get.find() se same instance use karenge.
  ProfileController controller = Get.put(ProfileController());

  @override
  void initState() {
    super.initState();
    // Master country list — sirf ek baar fetch karo (agar pehle se load nahi hua)
    if (controller.countryList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.getMasterCountryAPI(context);
      });
    }
  }

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
          'Personal Info',
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
                value: 1 / 3,
                color: AppColors.teal,
                label: 'Step 1 of 3: Personal Details',
              ),
              const SizedBox(height: 12),
              Text(
                'This helps your doctor instantly know who you are',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Photo picker
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navHome.withOpacity(0.5), width: 3),
                          color: AppColors.bgCardNavy,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 50),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              McCard(
                isPremium: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Details', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hint: 'Full Name',
                      controller: controller.fullNameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'Email Address',
                      controller: controller.emailCtrl,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hint: 'Date of Birth',
                      controller: controller.dobCtrl,
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: controller.selectedDob.value ?? DateTime(1990),
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.teal,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.teal,
                                ),
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
              ),
              const SizedBox(height: 20),

              McCard(
                isPremium: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Identity', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    Text('Gender', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Obx(
                      () => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: controller.genders.map((g) {
                          final sel = controller.selectedGender.value == g;
                          return GestureDetector(
                            onTap: () => controller.selectedGender.value = g,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.teal : AppColors.bgNavy,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: sel ? AppColors.teal : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                g,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: sel ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Obx(() {
                      if (controller.isCountryLoading.value) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.teal));
                      }
                      return McDropdown<CountryModel>(
                        hint: 'Nationality',
                        value: controller.selectedCountry.value,
                        items: controller.countryList,
                        selectedItemBuilder: (c) => Text(
                          c.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        itemLabel: (c) => '${c.flagEmoji}  ${c.name}',
                        prefixIcon: Icons.flag_circle_outlined,
                        onChanged: (v) {
                          controller.onCountrySelected(v);
                        },
                      );
                    }),
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
                    if (controller.fullNameCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter full name");
                      return;
                    }
                    if (controller.emailCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: "Please enter email");
                      return;
                    }
                    if (controller.selectedDob.value == null) {
                      Fluttertoast.showToast(msg: "Please select date of birth");
                      return;
                    }
                    if (controller.selectedGender.value.isEmpty) {
                      Fluttertoast.showToast(msg: "Please select gender");
                      return;
                    }
                    if (controller.selectedCountry.value == null) {
                      Fluttertoast.showToast(msg: "Please select nationality");
                      return;
                    }
                    controller.updateProfileAPI(context, () {
                      controller.getPatientProfileAPI(context); // Refresh data after update
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicalInfoScreen(null)),
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
