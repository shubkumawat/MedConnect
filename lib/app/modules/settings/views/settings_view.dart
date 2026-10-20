import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:healora/DataProvider/web_api_constant.dart';
import 'package:healora/app/core/Util/web_page_helper.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/services/storage_service.dart';
import '../../home/views/health_tips_screen.dart';
import '../../profile/controllers/profile_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _findByPhoneKey = 'privacy_find_by_phone';
  static const _dataVisibleKey = 'privacy_data_visible';

  bool _findByPhone = true;
  bool _dataVisible = true;
  bool _medReminders = true;
  bool _vacReminders = true;
  bool _qrAlerts = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = StorageService();
    final find = await storage.getBool(_findByPhoneKey, defaultValue: true);
    final visible = await storage.getBool(_dataVisibleKey, defaultValue: true);

    if (Get.isRegistered<ProfileController>()) {
      final p = Get.find<ProfileController>();
      _medReminders = p.medReminders.value;
      _vacReminders = p.vacReminders.value;
      _qrAlerts = p.qrAlerts.value;
    }

    setState(() {
      _findByPhone = find;
      _dataVisible = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5F2),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'App preferences and account',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _sectionTitle('Notification preferences'),
                _card(
                  children: [
                    _switchRow(
                      icon: Icons.medication_liquid_rounded,
                      title: 'Medication reminders',
                      value: _medReminders,
                      onChanged: (v) {
                        setState(() => _medReminders = v);
                        if (Get.isRegistered<ProfileController>()) {
                          Get.find<ProfileController>()
                              .setCareReminder(medication: v);
                        }
                      },
                    ),
                    _switchRow(
                      icon: Icons.vaccines_rounded,
                      title: 'Vaccination reminders',
                      value: _vacReminders,
                      onChanged: (v) {
                        setState(() => _vacReminders = v);
                        if (Get.isRegistered<ProfileController>()) {
                          Get.find<ProfileController>()
                              .setCareReminder(vaccination: v);
                        }
                      },
                    ),
                    _switchRow(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'QR scan alerts',
                      value: _qrAlerts,
                      last: true,
                      onChanged: (v) {
                        setState(() => _qrAlerts = v);
                        if (Get.isRegistered<ProfileController>()) {
                          Get.find<ProfileController>()
                              .setCareReminder(qrScan: v);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Privacy'),
                _card(
                  children: [
                    _switchRow(
                      icon: Icons.phone_android_rounded,
                      title: 'Who can find me by phone',
                      subtitle: 'Allow matching your number for family invites',
                      value: _findByPhone,
                      onChanged: (v) async {
                        setState(() => _findByPhone = v);
                        await StorageService().setBool(_findByPhoneKey, v);
                      },
                    ),
                    _switchRow(
                      icon: Icons.visibility_outlined,
                      title: 'Data visibility',
                      subtitle: 'Share summary with care providers via QR',
                      value: _dataVisible,
                      last: true,
                      onChanged: (v) async {
                        setState(() => _dataVisible = v);
                        await StorageService().setBool(_dataVisibleKey, v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Data & export'),
                _card(
                  children: [
                    _linkRow(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Export health records (PDF)',
                      subtitle: 'Full account or per patient from Records',
                      onTap: () {
                        Get.snackbar(
                          'Export',
                          'Open a disease in Records → Export PDF for that patient.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.white,
                          colorText: AppColors.textDark,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Help & support'),
                _card(
                  children: [
                    _linkRow(
                      icon: Icons.help_outline_rounded,
                      title: 'FAQ',
                      onTap: () => openWebPage(
                        title: 'FAQ',
                        url: WebApiConstant.WEB_HELP_URL,
                      ),
                    ),
                    _linkRow(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact support',
                      onTap: () => openWebPage(
                        title: 'Contact support',
                        url: WebApiConstant.WEB_HELP_URL,
                      ),
                    ),
                    _linkRow(
                      icon: Icons.report_outlined,
                      title: 'Report a problem',
                      onTap: () => openWebPage(
                        title: 'Report a problem',
                        url: WebApiConstant.WEB_HELP_URL,
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionTitle('Legal'),
                _card(
                  children: [
                    _linkRow(
                      icon: Icons.gavel_rounded,
                      title: 'Terms of Service',
                      onTap: () => openWebPage(
                        title: 'Terms of Service',
                        url: WebApiConstant.WEB_TERMS_URL,
                      ),
                    ),
                    _linkRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy Policy',
                      onTap: () => openWebPage(
                        title: 'Privacy Policy',
                        url: WebApiConstant.WEB_PRIVACY_URL,
                      ),
                    ),
                    _linkRow(
                      icon: Icons.policy_outlined,
                      title: 'Data Usage Policy',
                      onTap: () => openWebPage(
                        title: 'Data Usage Policy',
                        url: WebApiConstant.WEB_PRIVACY_URL,
                      ),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _card(
                  children: [
                    _linkRow(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Health Tips',
                      subtitle: 'Browse curated daily tips',
                      onTap: () => Get.to(() => const HealthTipsScreen()),
                      last: true,
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn(duration: 280.ms),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.captionBold.copyWith(
          color: AppColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool last = false,
  }) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          secondary: Icon(icon, color: AppColors.tealDark),
          title: Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textGray)),
          value: value,
          activeColor: AppColors.tealDark,
          onChanged: onChanged,
        ),
        if (!last) const Divider(height: 1, color: Color(0xFFE3EBE7)),
      ],
    );
  }

  Widget _linkRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool last = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.tealDark),
          title:
              Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textGray)),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textGray),
        ),
        if (!last) const Divider(height: 1, color: Color(0xFFE3EBE7)),
      ],
    );
  }
}
