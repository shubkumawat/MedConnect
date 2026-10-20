import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/home_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../family/model/family_member_model.dart';

class PatientSwitcherWidget extends GetView<HomeController> {
  const PatientSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.activePatient.value;
      if (active == null) return const SizedBox.shrink();

      return InkWell(
        onTap: () => _showPatientPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDeepBlue,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.accentTeal.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentTeal, width: 2),
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.backgroundDark,
                  child: Text(
                    active.name[0],
                    style: const TextStyle(color: AppColors.accentTeal, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        active.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.accentTeal, size: 18),
                    ],
                  ),
                  Text(
                    active.relation,
                    style: TextStyle(color: AppColors.white.withOpacity(0.6), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showPatientPicker(BuildContext context) {
    // Dummy list of patients for switcher
    final patients = [
      FamilyMemberModel(id: '1', name: 'John Doe', relation: 'Self', bloodGroup: 'O+'),
      FamilyMemberModel(id: '2', name: 'Jane Doe', relation: 'Spouse', bloodGroup: 'A+'),
      FamilyMemberModel(id: '3', name: 'Junior Doe', relation: 'Son', bloodGroup: 'O+'),
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.primaryDeepBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Switch Patient", style: AppTextStyles.poppinsBold18.copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            ...patients.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentTeal,
                    child: Text(p.name[0], style: const TextStyle(color: AppColors.primaryDeepBlue)),
                  ),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(p.relation, style: const TextStyle(color: Colors.white70)),
                  trailing: controller.activePatient.value?.id == p.id
                      ? const Icon(Icons.check_circle, color: AppColors.accentTeal)
                      : null,
                  onTap: () {
                    controller.switchPatient(p);
                    Get.back();
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
