import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Util/CustomButton/CustomButton.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

/// "A new version is available" popup shown when the Play Store / App Store
/// has a build newer than the one currently installed.
///
/// [isForced] hides the "Maybe Later" option and makes the dialog
/// non-dismissible — use only when the running build is unsafe to keep
/// using (e.g. a Play Store "high priority" update).
class AppUpdateDialog extends StatelessWidget {
  final String? currentVersion;
  final String? latestVersion;
  final bool isForced;
  final Future<void> Function() onUpdate;

  const AppUpdateDialog({
    super.key,
    this.currentVersion,
    this.latestVersion,
    this.isForced = false,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForced,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update Available',
                style: AppTextStyles.heading1.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'A new version of Healora is here with the latest '
                'features, improvements and bug fixes.',
                style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                textAlign: TextAlign.center,
              ),
              if (currentVersion != null && latestVersion != null) ...[
                const SizedBox(height: 16),
                _VersionRow(current: currentVersion!, latest: latestVersion!),
              ],
              const SizedBox(height: 24),
              CustomPrimaryButton(
                text: 'Update Now',
                icon: Icons.arrow_upward_rounded,
                onTap: () {
                  onUpdate();
                  if (isForced) return;
                  if (Get.isDialogOpen ?? false) Get.back();
                },
              ),
              if (!isForced) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Maybe Later',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.textGray),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String current;
  final String latest;

  const _VersionRow({required this.current, required this.latest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('v$current', style: AppTextStyles.caption.copyWith(color: AppColors.textGray)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textGray),
          ),
          Text(
            'v$latest',
            style: AppTextStyles.captionBold.copyWith(color: AppColors.tealDark),
          ),
        ],
      ),
    );
  }
}
