import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/services/storage_service.dart';
import '../../modules/login/views/login_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';
import 'CustomButton/CustomButton.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.bgCardNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.statusRed.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.statusRed, size: 32),
                ),
                const SizedBox(height: 20),
                Text('Log Out?', style: AppTextStyles.heading2),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out of your account?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: CustomOutlineButton(
                        text: 'Cancel',
                        onTap: () => Navigator.pop(dialogContext),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomPrimaryButton(
                        text: 'Logout',
                        color: AppColors.statusRed,
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          await _performLogout();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _performLogout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    final storage = StorageService();
    await storage.setBool(StorageService.isLogin, false);
    await storage.setString(StorageService.token, "");
    Get.offAll(() => const LoginScreen(), transition: Transition.fade);
  }
}
