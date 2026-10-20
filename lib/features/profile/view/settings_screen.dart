import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../notifications/view/reminder_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("Preferences"),
          _buildSettingCard(
            child: SwitchListTile(
              title: const Text("Push Notifications", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Get alerts for medicine & appointments", style: TextStyle(color: Colors.white54)),
              value: true,
              activeColor: AppColors.accentTeal,
              onChanged: (val) {},
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingCard(
            child: ListTile(
              title: const Text("Reminder Settings", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Customize dosage & schedule alerts", style: TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => Get.to(() => const ReminderSettingsScreen()),
            ),
          ),
          
          const SizedBox(height: 30),
          _buildSectionHeader("App Info"),
          _buildSettingCard(
            child: Column(
              children: [
                _buildListTile("Privacy Policy", Icons.privacy_tip_outlined),
                const Divider(color: Colors.white12, height: 1),
                _buildListTile("Terms of Service", Icons.description_outlined),
                const Divider(color: Colors.white12, height: 1),
                _buildListTile("About Med Connect", Icons.info_outline),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
            child: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDeepBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildListTile(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {},
    );
  }
}
