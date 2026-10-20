import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/family_controller.dart';
import 'add_family_member_screen.dart';

class MyPatientsScreen extends GetView<FamilyController> {
  const MyPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text("Family & Patients", style: AppTextStyles.poppinsBold24),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.familyMembers.length,
            itemBuilder: (context, index) {
              final member = controller.familyMembers[index];
              return Card(
                color: AppColors.primaryDeepBlue,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.accentTeal,
                    child: Text(
                      member.name[0],
                      style: const TextStyle(color: AppColors.primaryDeepBlue, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    "${member.relation} • ${member.bloodGroup}",
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: member.isSelf
                      ? const Chip(
                          label: Text("Self", style: TextStyle(color: AppColors.primaryDeepBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: AppColors.accentTeal,
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _confirmDelete(member),
                        ),
                  onTap: () {
                    controller.switchActivePatient(member);
                    Get.snackbar("Patient Switched", "Active records: ${member.name}",
                        backgroundColor: AppColors.accentTeal, colorText: AppColors.primaryDeepBlue);
                  },
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentTeal,
        onPressed: () => Get.to(() => const AddFamilyMemberScreen()),
        child: const Icon(Icons.person_add, color: AppColors.primaryDeepBlue),
      ),
    );
  }

  void _confirmDelete(member) {
    Get.defaultDialog(
      title: "Remove Member",
      middleText: "Are you sure you want to remove ${member.name} from your family list?",
      backgroundColor: AppColors.primaryDeepBlue,
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: "Remove",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteMember(member.id);
        Get.back();
      },
    );
  }
}
