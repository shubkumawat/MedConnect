import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controller/profile_controller.dart';
import '../model/emergency_contact_model.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context, controller),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      body: Obx(() => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.emergencyContacts.length,
        itemBuilder: (context, index) {
          final contact = controller.emergencyContacts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: AppColors.primaryDeepBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: contact.isPrimary ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: contact.isPrimary ? Colors.redAccent : AppColors.accentTeal,
                child: Icon(
                  contact.isPrimary ? Icons.favorite : Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                contact.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${contact.relation} • ${contact.phoneNumber}",
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.accentTeal),
                    onPressed: () {}, // Trigger Call
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => controller.removeContact(contact.id),
                  ),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  void _showAddContactDialog(BuildContext context, ProfileController controller) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    Get.defaultDialog(
      title: "Add Emergency Contact",
      backgroundColor: AppColors.primaryDeepBlue,
      titleStyle: const TextStyle(color: Colors.white),
      content: Column(
        children: [
          _buildTextField(nameController, "Name", Icons.person),
          const SizedBox(height: 10),
          _buildTextField(phoneController, "Phone Number", Icons.phone),
          const SizedBox(height: 10),
          _buildTextField(relationController, "Relation", Icons.family_restroom),
        ],
      ),
      textConfirm: "Add",
      textCancel: "Cancel",
      confirmTextColor: AppColors.primaryDeepBlue,
      buttonColor: AppColors.accentTeal,
      onConfirm: () {
        if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
          controller.addContact(EmergencyContactModel(
            id: DateTime.now().toString(),
            name: nameController.text,
            phoneNumber: phoneController.text,
            relation: relationController.text,
          ));
          Get.back();
        }
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: AppColors.accentTeal),
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
