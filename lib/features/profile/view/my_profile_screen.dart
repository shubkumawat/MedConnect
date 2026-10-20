import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import 'emergency_contacts_screen.dart';
import 'health_tips_screen.dart';
import 'settings_screen.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryDeepBlue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          const Text("John Doe", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("+91 9876543210", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.contact_phone, color: AppColors.accentTeal),
            title: const Text("Emergency Contacts"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const EmergencyContactsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.tips_and_updates, color: AppColors.accentTeal),
            title: const Text("Health Tips"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const HealthTipsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.accentTeal),
            title: const Text("Settings"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const SettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
