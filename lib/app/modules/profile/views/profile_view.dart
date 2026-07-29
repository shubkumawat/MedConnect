import 'emergency_info_view.dart';
import 'medical_info_view.dart';
import 'personal_info_view.dart';
import 'package:digitalhealth/app/data/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../home/controllers/home_controller.dart';
import '../../login/views/login_view.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:digitalhealth/app/core/Util/LogoutWidget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final controller = Get.put(ProfileController());
  final storage = StorageService();

  RxBool _medReminders = true.obs;
  RxBool _vacReminders = true.obs;
  RxBool _qrAlerts = true.obs;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    controller.getPatientProfileAPI(context);
  }

  Future<void> _loadReminders() async {
    final m = await storage.getBool(StorageService.medReminders);
    final v = await storage.getBool(StorageService.vacReminders);
    final q = await storage.getBool(StorageService.qrAlerts);
    
    // Default to true if not set before (assuming first time)
    // Or you can check if they exist in prefs
    _medReminders.value = m;
    _vacReminders.value = v;
    _qrAlerts.value = q;
  }

  void _toggleMed(bool val) {
    _medReminders.value = val;
    storage.setBool(StorageService.medReminders, val);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().showMedReminders.value = val;
    }
  }

  void _toggleVac(bool val) {
    _vacReminders.value = val;
    storage.setBool(StorageService.vacReminders, val);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().showVacReminders.value = val;
    }
  }

  void _toggleQR(bool val) {
    _qrAlerts.value = val;
    storage.setBool(StorageService.qrAlerts, val);
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
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Obx(() {
        // if (controller.isLoading.value) {
        //   return const Center(child: CircularProgressIndicator());
        // }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                McCard(
                  color: AppColors.bgCardNavy,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          PatientAvatar(
                            initials: controller.fullNameCtrl.text.isNotEmpty
                                ? controller.fullNameCtrl.text.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                : 'P',
                            color: AppColors.primary,
                            isActive: false,
                            size: 90,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.fullNameCtrl.text.isEmpty ? 'Update Name' : controller.fullNameCtrl.text,
                        style: AppTextStyles.heading2.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.age.value > 0 ? controller.age.value : "--"}y · '
                        '${controller.bloodGroup.value.isEmpty ? "--" : controller.bloodGroup.value} · '
                        '${controller.selectedGender.value.isEmpty ? "--" : controller.selectedGender.value.capitalizeFirst}',
                        style: AppTextStyles.body.copyWith(color: AppColors.teal, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        controller.mobileNumber.value,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),

                      // Completeness bar
                      McProgressBar(
                        value: 0.75,
                        color: AppColors.teal,
                        label: 'Profile 75% complete — add your allergies',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('My Info', style: AppTextStyles.heading3.copyWith(fontSize: 20)),
                const SizedBox(height: 16),

                McCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.badge_outlined, color: AppColors.primary, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Medical Identity', style: AppTextStyles.bodyBold),
                                Text('Personal, Medical & Emergency Info', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomPrimaryButton(
                        text: 'Edit Profile Flow',
                        onTap: () async {
                          Get.to(() => const PersonalInfoScreen(null));
                        },
                        color: AppColors.primary,
                        height: 45,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text('More Options', style: AppTextStyles.heading3.copyWith(fontSize: 20)),
                const SizedBox(height: 16),

                SettingRow(icon: Icons.security_rounded, title: 'Insurance Details', iconColor: AppColors.primary, onTap: () {}),
                SettingRow(icon: Icons.file_download_outlined, title: 'Export Records (PDF)', iconColor: AppColors.orange, onTap: () {}),

                const SizedBox(height: 32),
                Text('Reminders', style: AppTextStyles.heading3.copyWith(fontSize: 20)),
                const SizedBox(height: 16),

                Obx(() => _ReminderToggle(
                  icon: Icons.medication_rounded,
                  label: 'Medication Reminders',
                  color: AppColors.orange,
                  value: _medReminders.value,
                  onChanged: _toggleMed,
                )),
                const SizedBox(height: 12),
                Obx(() => _ReminderToggle(
                  icon: Icons.vaccines_rounded,
                  label: 'Vaccination Reminders',
                  color: AppColors.teal,
                  value: _vacReminders.value,
                  onChanged: _toggleVac,
                )),
                const SizedBox(height: 12),
                Obx(() => _ReminderToggle(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'QR Scan Alerts',
                  color: AppColors.primary,
                  value: _qrAlerts.value,
                  onChanged: _toggleQR,
                )),

                const SizedBox(height: 32),
                Text('Settings', style: AppTextStyles.heading3.copyWith(fontSize: 20)),
                const SizedBox(height: 16),

                SettingRow(icon: Icons.language_rounded, title: 'Language: English', onTap: () {}),
                SettingRow(icon: Icons.privacy_tip_outlined, title: 'Privacy Settings', onTap: () {}),
                SettingRow(icon: Icons.help_outline_rounded, title: 'Help & Support / FAQ', onTap: () {}),
                SettingRow(icon: Icons.info_outline_rounded, title: 'Terms & Privacy Policy', onTap: () {}),
                SettingRow(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  iconColor: AppColors.statusRed,
                  bgColor: AppColors.statusRed.withOpacity(0.08),
                  onTap: () {},
                ),
                SettingRow(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  iconColor: AppColors.orange,
                  onTap: () => LogoutDialog.show(context),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReminderToggle({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textTail))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
