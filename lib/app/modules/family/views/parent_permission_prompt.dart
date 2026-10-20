import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/menstrual_cycle_model.dart';
import '../controllers/family_member_controller.dart';

Future<void> showParentPermissionPrompt(ParentPermission permission) async {
  if (!permission.canRespond || !permission.isPending) return;
  if (Get.isDialogOpen == true) return;

  final parentName = (permission.parentName ?? 'Your parent').trim();
  await Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text(
        'Parent access request',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
      content: Text(
        '$parentName is asking for permission to manage your health records.',
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Get.back();
            final family = Get.isRegistered<FamilyMemberController>()
                ? Get.find<FamilyMemberController>()
                : Get.put(FamilyMemberController());
            await family.respondParentPermission(
              context: Get.context!,
              action: 'deny',
            );
          },
          child: const Text('Deny',
              style: TextStyle(color: AppColors.statusRed, fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final family = Get.isRegistered<FamilyMemberController>()
                ? Get.find<FamilyMemberController>()
                : Get.put(FamilyMemberController());
            await family.respondParentPermission(
              context: Get.context!,
              action: 'grant',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.tealDark,
            foregroundColor: Colors.white,
          ),
          child: const Text('Grant', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}
