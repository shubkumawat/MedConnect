import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/qr_controller.dart';

class QrScreen extends StatelessWidget {
  final String patientName;
  final String? patientId;
  final String? profilePhoto;
  final String? initials;
  /// Own QR expire uses `{}`; family passes patient_id.
  final bool isSelf;

  const QrScreen({
    super.key,
    required this.patientName,
    this.patientId,
    this.profilePhoto,
    this.initials,
    this.isSelf = true,
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
        isSelf: isSelf,
      ),
      tag: tag,
    );

    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Obx(() {
        if (controller.isLoading.value && controller.qrData.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }

        final qr = controller.qrData.value?.qr;
        final imageUrl = qr?.resolvedImageUrl;
        final expired = controller.isExpired;
        final photo = _normalizePhoto(profilePhoto);

        return Column(
          children: [
            _QrHeader(
              topPad: top,
              patientName: patientName,
              photo: photo,
              initials: controller.initials ?? _initialsFromName(patientName),
              displayId: qr?.displayId,
              onBack: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + bottom),
                child: Column(
                  children: [
                    _QrCard(
                      imageUrl: imageUrl,
                      expired: expired,
                      displayId: qr?.displayId,
                      onExpiredTap: () => controller.regenerateQr(),
                    ),
                    const SizedBox(height: 14),
                    _TimerCard(
                      label: controller.timerLabel,
                      subtitle: controller.timerSubtitle,
                      color: controller.timerColor,
                      progress: controller.progress,
                      expired: expired,
                      expiresAt: controller.expiresAtLabel,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'New QR',
                            icon: Icons.refresh_rounded,
                            filled: true,
                            loading: controller.isRegenerating.value,
                            onTap: () => controller.regenerateQr(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionBtn(
                            label: 'Delete QR',
                            icon: Icons.delete_outline_rounded,
                            filled: false,
                            destructive: true,
                            loading: controller.isDeleting.value,
                            onTap: () => _confirmDeleteQr(context, controller),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'How to use',
                      body:
                          'Show this QR to your doctor or clinic. It stays valid for ${controller.activeExpiryMinutes} minutes, then tap New QR for a fresh code.',
                    ),
                    const SizedBox(height: 10),
                    _MetaRow(
                      icon: Icons.history_rounded,
                      label: 'Last scanned',
                      value: controller.lastScannedLabel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmDeleteQr(
    BuildContext context,
    QrController controller,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete QR?'),
        content: const Text(
          'This health QR will be removed. You can generate a new one anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE03A3A)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteQr();
    }
  }

  static String? _normalizePhoto(String? raw) {
    var url = (raw ?? '').trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return null;
    if (url.startsWith('//')) url = 'http:$url';
    if (url.startsWith('/')) {
      url = 'http://medconnect.airainnovations.com$url';
    }
    return url;
  }

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _QrHeader extends StatelessWidget {
  final double topPad;
  final String patientName;
  final String? photo;
  final String initials;
  final String? displayId;
  final VoidCallback onBack;

  const _QrHeader({
    required this.topPad,
    required this.patientName,
    required this.photo,
    required this.initials,
    required this.displayId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
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
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo/ic_logo_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Secure · 10 min access',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: const Text(
                  '10 MIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photo != null
                      ? Image.network(
                          photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayId?.isNotEmpty == true
                            ? displayId!
                            : 'Patient health passport',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR card ──────────────────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  final String? imageUrl;
  final bool expired;
  final String? displayId;
  final VoidCallback onExpiredTap;

  const _QrCard({
    required this.imageUrl,
    required this.expired,
    required this.displayId,
    required this.onExpiredTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3EBE7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Scan to view health summary',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 248,
                height: 248,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3EBE7)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorFiltered(
                    colorFilter: expired
                        ? const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation)
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
              ),
              if (expired)
                GestureDetector(
                  onTap: onExpiredTap,
                  child: Container(
                    width: 248,
                    height: 248,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 36),
                        SizedBox(height: 10),
                        Text(
                          'QR Expired',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to generate new (10 min)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (displayId != null && displayId!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayId!,
                style: const TextStyle(
                  color: AppColors.tealDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _placeholder() {
    return const ColoredBox(
      color: Color(0xFFF3F7F5),
      child: Center(
        child: Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.teal),
      ),
    );
  }
}

// ── Timer ────────────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final double progress;
  final bool expired;
  final String expiresAt;

  const _TimerCard({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.progress,
    required this.expired,
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expired ? 'Expired' : 'Time remaining',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expired ? '00:00' : label,
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expires',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    expiresAt,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: expired ? 0 : progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8F2EE),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actions / info ───────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool loading;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.loading = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFE03A3A);
    final fg = destructive ? danger : AppColors.tealDark;
    final border = destructive
        ? danger.withValues(alpha: 0.45)
        : AppColors.teal.withValues(alpha: 0.45);

    return SizedBox(
      height: 50,
      child: filled
          ? ElevatedButton.icon(
              onPressed: loading ? null : onTap,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.tealDark.withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: loading ? null : onTap,
              icon: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: fg,
                      ),
                    )
                  : Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: fg,
                side: BorderSide(color: border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String body;
  const _InfoCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.tealDark),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
