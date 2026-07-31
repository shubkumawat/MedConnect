import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/qr_controller.dart';

class QrScreen extends StatelessWidget {
  final String patientName;
  final String? patientId;
  final String? profilePhoto;
  final String? initials;

  const QrScreen({
    super.key,
    required this.patientName,
    this.patientId,
    this.profilePhoto,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'qr_${patientId ?? patientName}';
    if (Get.isRegistered<QrController>(tag: tag)) {
      Get.delete<QrController>(tag: tag);
    }
    final controller = Get.put(
      QrController(
        patientName: patientName,
        patientId: patientId,
        profilePhoto: profilePhoto,
        initials: initials ?? _initialsFromName(patientName),
      ),
      tag: tag,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "$patientName's Health QR",
        showBack: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.qrData.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        final qr = controller.qrData.value?.qr;
        final imageUrl = qr?.resolvedImageUrl;
        final expired = controller.isExpired;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Patient context
              McCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _Avatar(
                      photo: profilePhoto,
                      initials: controller.initials ?? _initialsFromName(patientName),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$patientName's Health QR",
                            style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            qr?.displayId ?? 'Secure patient access',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // QR Code
              McCard(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ColorFiltered(
                            colorFilter: expired
                                ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 240,
                                    height: 240,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => _qrPlaceholder(),
                                  )
                                : _qrPlaceholder(),
                          ),
                        ),
                        if (expired)
                          GestureDetector(
                            onTap: () => controller.regenerateQr(),
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'QR Expired — Tap to Generate New',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      qr?.displayId ?? '—',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live countdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: controller.timerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: controller.timerColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, color: controller.timerColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      expired ? '00:00 remaining' : controller.timerLabel,
                      style: AppTextStyles.bodyBold.copyWith(color: controller.timerColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Expiry options
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Expiry', style: AppTextStyles.captionBold.copyWith(color: AppColors.teal)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: controller.allowedExpiryMinutes.map((m) {
                  final selected = controller.selectedExpiryMinutes.value == m;
                  return ChoiceChip(
                    label: Text('${m}m'),
                    selected: selected,
                    onSelected: (_) => controller.selectedExpiryMinutes.value = m,
                    selectedColor: AppColors.teal.withOpacity(0.2),
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: selected ? AppColors.teal : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              Obx(() => CustomPrimaryButton(
                    text: 'Regenerate QR',
                    icon: Icons.refresh_rounded,
                    color: AppColors.teal,
                    isLoading: controller.isRegenerating.value,
                    onTap: () => controller.regenerateQr(),
                  )),
              const SizedBox(height: 10),
              CustomOutlineButton(
                text: 'Share QR',
                onTap: () => controller.shareQr(),
                borderColor: AppColors.primary,
                textColor: AppColors.primary,
              ),
              const SizedBox(height: 16),

              McCard(
                color: AppColors.bgCardDark,
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.orange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Show this to your doctor. They can scan it to view your health summary securely.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(controller.lastScannedLabel, style: AppTextStyles.caption),
              const SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }

  Widget _qrPlaceholder() {
    return Container(
      width: 240,
      height: 240,
      color: AppColors.bgCardDark,
      child: const Center(
        child: Icon(Icons.qr_code_2_rounded, size: 80, color: AppColors.teal),
      ),
    );
  }

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  final String? photo;
  final String initials;
  const _Avatar({this.photo, required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.teal.withOpacity(0.15),
      backgroundImage: (photo != null && photo!.isNotEmpty) ? NetworkImage(photo!) : null,
      child: (photo == null || photo!.isEmpty)
          ? Text(initials, style: AppTextStyles.bodyBold.copyWith(color: AppColors.teal))
          : null,
    );
  }
}
