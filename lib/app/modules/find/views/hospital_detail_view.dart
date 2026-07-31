import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/doctor_model.dart';
import '../controllers/find_controller.dart';

class HospitalDetailView extends StatefulWidget {
  final String hospitalId;
  const HospitalDetailView({super.key, required this.hospitalId});

  @override
  State<HospitalDetailView> createState() => _HospitalDetailViewState();
}

class _HospitalDetailViewState extends State<HospitalDetailView> {
  late final FindController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FindController>()
        ? Get.find<FindController>()
        : Get.put(FindController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHospitalDetail(widget.hospitalId);
    });
  }

  Future<void> _launch(Uri uri, {String? errorMsg}) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        Get.snackbar(
          'Unable to open',
          errorMsg ?? 'No app available for this action.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Unable to open',
        errorMsg ?? 'Something went wrong.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
  }

  String _cleanPhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  Future<void> _callPhone(String phone) async {
    final cleaned = _cleanPhone(phone);
    if (cleaned.isEmpty) {
      Get.snackbar('No number', 'Phone number not available.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await _launch(
      Uri(scheme: 'tel', path: cleaned),
      errorMsg: 'Could not open phone dialer.',
    );
  }

  Future<void> _sendEmail(String email) async {
    final value = email.trim();
    if (value.isEmpty) {
      Get.snackbar('No email', 'Email address not available.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await _launch(
      Uri(scheme: 'mailto', path: value),
      errorMsg: 'Could not open email app.',
    );
  }

  Future<void> _openWebsite(String url) async {
    final value = url.trim();
    if (value.isEmpty) {
      Get.snackbar('No website', 'Website not available.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final hasScheme =
        value.startsWith('http://') || value.startsWith('https://');
    await _launch(
      Uri.parse(hasScheme ? value : 'https://$value'),
      errorMsg: 'Could not open website.',
    );
  }

  Future<void> _openDirections(HospitalDetail hospital) async {
    if (hospital.latitude != null &&
        hospital.longitude != null &&
        hospital.latitude!.isNotEmpty &&
        hospital.longitude!.isNotEmpty) {
      await _launch(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
        ),
        errorMsg: 'Could not open Maps.',
      );
      return;
    }
    if (hospital.address.trim().isEmpty) {
      Get.snackbar('No address', 'Address not available.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await _launch(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(hospital.address)}',
      ),
      errorMsg: 'Could not open Maps.',
    );
  }

  void _showReviewSheet(HospitalDetail hospital) {
    Get.bottomSheet(
      _WriteReviewSheet(
        hospital: hospital,
        onSubmit: (rating, comment) async {
          await controller.submitReview(
            id: widget.hospitalId,
            rating: rating,
            comment: comment,
            isHospital: true,
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: true,
      enableDrag: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Obx(() {
        if (controller.isDetailLoading.value &&
            controller.hospitalDetail.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }
        final hospital = controller.hospitalDetail.value;
        if (hospital == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 48, color: AppColors.teal),
                const SizedBox(height: 12),
                Text('Hospital not found', style: AppTextStyles.bodyBold),
                TextButton(
                  onPressed: () =>
                      controller.fetchHospitalDetail(widget.hospitalId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return _DetailBody(
          hospital: hospital,
          onBack: () => Get.back(),
          onCall: () => _callPhone(hospital.phone),
          onEmergency: () => _callPhone(
            hospital.emergencyPhone.isNotEmpty
                ? hospital.emergencyPhone
                : hospital.phone,
          ),
          onDirections: () => _openDirections(hospital),
          onEmail: () => _sendEmail(hospital.email),
          onWebsite: () => _openWebsite(hospital.website ?? ''),
          onReview: () => _showReviewSheet(hospital),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BODY
// ═══════════════════════════════════════════════════════════════════════════

class _DetailBody extends StatelessWidget {
  final HospitalDetail hospital;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onEmergency;
  final VoidCallback onDirections;
  final VoidCallback onEmail;
  final VoidCallback onWebsite;
  final VoidCallback onReview;

  const _DetailBody({
    required this.hospital,
    required this.onBack,
    required this.onCall,
    required this.onEmergency,
    required this.onDirections,
    required this.onEmail,
    required this.onWebsite,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final rating = double.tryParse(hospital.averageRating) ?? 0;
    final hasWebsite =
        hospital.website != null && hospital.website!.trim().isNotEmpty;
    final hasEmail = hospital.email.trim().isNotEmpty;
    final hasPhone = hospital.phone.trim().isNotEmpty;
    final hasAddress = hospital.address.trim().isNotEmpty;
    final hasEmergency = hospital.emergencyPhone.trim().isNotEmpty;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero ──
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300 + top,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hospital.bannerUrl != null && hospital.bannerUrl!.isNotEmpty
                        ? Image.network(
                            hospital.bannerUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _CareHeroAnimation(),
                          )
                        : const _CareHeroAnimation(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.72),
                          ],
                          stops: const [0, 0.35, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: top + 8,
                      left: 12,
                      child: _RoundBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
                    ),
                    if (hasPhone)
                      Positioned(
                        top: top + 8,
                        right: 12,
                        child: _RoundBtn(
                          icon: Icons.call_rounded,
                          onTap: onCall,
                        ),
                      ),
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 36,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (hospital.isVerified)
                                const _StatusChip(
                                  icon: Icons.verified_rounded,
                                  label: 'Verified',
                                  color: AppColors.teal,
                                ),
                              if (hospital.isVerified && hospital.isFeatured)
                                const SizedBox(width: 8),
                              if (hospital.isFeatured)
                                const _StatusChip(
                                  icon: Icons.workspace_premium_rounded,
                                  label: 'Featured',
                                  color: AppColors.orange,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hospital.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (hospital.hospitalType.isNotEmpty)
                                hospital.hospitalType,
                              if (hospital.cityName.isNotEmpty) hospital.cityName,
                            ].join('  ·  '),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Sheet ──
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F6F4),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top rating / identity card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: _TopRatingCard(
                          hospital: hospital,
                          rating: rating,
                          onWriteReview: onReview,
                        )
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.06, end: 0),
                      ),

                      // Quick actions — always 4, clearly tappable
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.call_rounded,
                                label: 'Call',
                                color: AppColors.teal,
                                enabled: hasPhone,
                                onTap: onCall,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.directions_rounded,
                                label: 'Maps',
                                color: AppColors.primary,
                                enabled: hasAddress ||
                                    (hospital.latitude != null &&
                                        hospital.longitude != null),
                                onTap: onDirections,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.email_rounded,
                                label: 'Email',
                                color: AppColors.orange,
                                enabled: hasEmail,
                                onTap: onEmail,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.language_rounded,
                                label: 'Website',
                                color: AppColors.accentBlue,
                                enabled: hasWebsite,
                                onTap: onWebsite,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 350.ms)
                          .slideY(begin: 0.06, end: 0),

                      // Contact block — each row opens action
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact & location',
                                style: AppTextStyles.heading3),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _ContactActionRow(
                                    icon: Icons.location_on_rounded,
                                    color: AppColors.teal,
                                    title: 'Address',
                                    value: hasAddress
                                        ? hospital.address
                                        : 'Not available',
                                    actionHint: 'Open in Maps',
                                    enabled: hasAddress ||
                                        (hospital.latitude != null &&
                                            hospital.longitude != null),
                                    onTap: onDirections,
                                    showDivider: true,
                                  ),
                                  _ContactActionRow(
                                    icon: Icons.call_rounded,
                                    color: AppColors.primary,
                                    title: 'Phone',
                                    value: hasPhone
                                        ? hospital.phone
                                        : 'Not available',
                                    actionHint: 'Tap to call',
                                    enabled: hasPhone,
                                    onTap: onCall,
                                    showDivider: true,
                                  ),
                                  _ContactActionRow(
                                    icon: Icons.emergency_rounded,
                                    color: AppColors.statusRed,
                                    title: 'Emergency',
                                    value: hasEmergency
                                        ? hospital.emergencyPhone
                                        : 'Not available',
                                    actionHint: 'Emergency call',
                                    enabled: hasEmergency,
                                    onTap: onEmergency,
                                    showDivider: true,
                                  ),
                                  _ContactActionRow(
                                    icon: Icons.email_rounded,
                                    color: AppColors.orange,
                                    title: 'Email',
                                    value: hasEmail
                                        ? hospital.email
                                        : 'Not available',
                                    actionHint: 'Send email',
                                    enabled: hasEmail,
                                    onTap: onEmail,
                                    showDivider: hasWebsite,
                                  ),
                                  if (hasWebsite)
                                    _ContactActionRow(
                                      icon: Icons.language_rounded,
                                      color: AppColors.accentBlue,
                                      title: 'Website',
                                      value: hospital.website!,
                                      actionHint: 'Open website',
                                      enabled: true,
                                      onTap: onWebsite,
                                      showDivider: false,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 140.ms, duration: 350.ms),

                      // About
                      if (hospital.about.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                          child: _SectionCard(
                            title: 'About',
                            child: Text(
                              hospital.about,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textMuted,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),

                      // Facilities
                      if (hospital.facilities.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: _SectionCard(
                            title: 'Facilities',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: hospital.facilities
                                  .map((f) => _FacilityPill(label: f.name))
                                  .toList(),
                            ),
                          ),
                        ),

                      // Departments
                      if (hospital.departments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Departments',
                                  style: AppTextStyles.heading3),
                              const SizedBox(height: 12),
                              ...hospital.departments.map(
                                (d) => _DeptTile(
                                  name: d.name,
                                  description: d.description,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Reviews
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                        child: _ReviewsSection(
                          hospital: hospital,
                          onWriteReview: onReview,
                        ),
                      ),

                      SizedBox(height: 120 + bottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Sticky bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_rounded, size: 20),
                      label: const Text(
                        'Directions',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.tealDark,
                        side: BorderSide(
                          color: AppColors.teal.withValues(alpha: 0.45),
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: hasPhone || hasEmergency ? onCall : null,
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: Text(
                        hasPhone ? 'Call ${hospital.phone}' : 'Call',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════
// TOP RATING CARD
// ═══════════════════════════════════════════════════════════════════════════

class _TopRatingCard extends StatelessWidget {
  final HospitalDetail hospital;
  final double rating;
  final VoidCallback onWriteReview;

  const _TopRatingCard({
    required this.hospital,
    required this.rating,
    required this.onWriteReview,
  });

  String get _label {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very good';
    if (rating >= 3.0) return 'Good';
    if (rating > 0) return 'Average';
    return 'New';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24),bottomRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo with ring
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.teal.withValues(alpha: 0.5),
                        AppColors.primary.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: hospital.logoUrl != null &&
                              hospital.logoUrl!.isNotEmpty
                          ? Image.network(
                              hospital.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _CareLogoPlaceholder(),
                            )
                          : const _CareLogoPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall rating',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : '—',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _label,
                              style: const TextStyle(
                                color: Color(0xFF8A6A00),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                i < rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFC107),
                                size: 18,
                              ),
                            );
                          }),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${hospital.totalReviews} reviews',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider strip
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.border.withValues(alpha: 0.7),
          ),
          // CTA row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _MiniStat(
                        icon: Icons.verified_rounded,
                        label: hospital.isVerified ? 'Verified' : 'Listed',
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 8),
                      _MiniStat(
                        icon: Icons.people_alt_rounded,
                        label: hospital.totalReviews > 0
                            ? '${hospital.totalReviews}+ rated'
                            : 'Be first',
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onWriteReview();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B6E4F), Color(0xFF1B9E8E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.white, size: 15),
                            SizedBox(width: 6),
                            Text(
                              'Rate',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// NO-IMAGE HERO ANIMATION — hospital / doctor / patient
// ═══════════════════════════════════════════════════════════════════════════

class _CareHeroAnimation extends StatefulWidget {
  const _CareHeroAnimation();

  @override
  State<_CareHeroAnimation> createState() => _CareHeroAnimationState();
}

class _CareHeroAnimationState extends State<_CareHeroAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _float;
  late final AnimationController _scene;
  int _index = 0;

  static const _scenes = [
    _CareScene(
      icon: Icons.local_hospital_rounded,
      title: 'Hospital care',
      subtitle: 'Trusted facilities nearby',
    ),
    _CareScene(
      icon: Icons.medical_services_rounded,
      title: 'Expert doctors',
      subtitle: 'Specialists you can rely on',
    ),
    _CareScene(
      icon: Icons.family_restroom_rounded,
      title: 'Patient first',
      subtitle: 'Care for your whole family',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _scene = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cycleScenes();
  }

  Future<void> _cycleScenes() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2600));
      if (!mounted) return;
      await _scene.forward();
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _scenes.length);
      _scene.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _float.dispose();
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _float, _scene]),
      builder: (context, _) {
        final pulse = Curves.easeInOut.transform(_pulse.value);
        final float = Curves.easeInOut.transform(_float.value);
        final fadeOut = _scene.value;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF084C3A),
                Color(0xFF0F6B58),
                Color(0xFF1B9E8E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Soft floating orbs
              Positioned(
                top: 40 + float * 12,
                right: -20,
                child: _orb(140, 0.07 + pulse * 0.03),
              ),
              Positioned(
                bottom: 60 - float * 10,
                left: -30,
                child: _orb(120, 0.08),
              ),
              Positioned(
                top: 100,
                left: 30 + float * 8,
                child: _orb(46, 0.1),
              ),
              Positioned(
                bottom: 120,
                right: 40 - float * 6,
                child: _orb(34, 0.12),
              ),

              // Pulse rings behind main icon
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.0 + pulse * 0.35,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: 0.12 * (1 - pulse),
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 1.0 + pulse * 0.18,
                        child: Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: (1 - fadeOut).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 1 - fadeOut * 0.15,
                          child: Transform.translate(
                            offset: Offset(0, float * -6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.14),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.28),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    scene.icon,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  scene.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  scene.subtitle,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Mini floating care icons
              Positioned(
                top: 70 + float * 10,
                left: 28,
                child: _miniIcon(Icons.favorite_rounded, pulse),
              ),
              Positioned(
                top: 90 - float * 8,
                right: 36,
                child: _miniIcon(Icons.health_and_safety_rounded, 1 - pulse),
              ),
              Positioned(
                bottom: 90 + float * 6,
                left: 48,
                child: _miniIcon(Icons.medication_rounded, pulse * 0.8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _miniIcon(IconData icon, double t) {
    return Opacity(
      opacity: 0.35 + t * 0.35,
      child: Transform.scale(
        scale: 0.9 + t * 0.15,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _CareScene {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CareScene({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _CareLogoPlaceholder extends StatefulWidget {
  const _CareLogoPlaceholder();

  @override
  State<_CareLogoPlaceholder> createState() => _CareLogoPlaceholderState();
}

class _CareLogoPlaceholderState extends State<_CareLogoPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _index = 0;

  static const _icons = [
    Icons.local_hospital_rounded,
    Icons.medical_services_rounded,
    Icons.personal_injury_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _rotate();
  }

  Future<void> _rotate() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2200));
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _icons.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.tealDark.withValues(alpha: 0.15 + t * 0.08),
                AppColors.primary.withValues(alpha: 0.12),
              ],
            ),
          ),
          child: Center(
            child: Transform.scale(
              scale: 0.92 + t * 0.1,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Icon(
                  _icons[_index],
                  key: ValueKey(_index),
                  color: AppColors.tealDark,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : AppColors.textGray;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.22)
                  : AppColors.border.withValues(alpha: 0.7),
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: enabled
                      ? LinearGradient(
                          colors: [c.withValues(alpha: 0.85), c],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: enabled ? null : AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String actionHint;
  final bool enabled;
  final VoidCallback onTap;
  final bool showDivider;

  const _ContactActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.actionHint,
    required this.enabled,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: enabled ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        color: enabled ? color : AppColors.textGray, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: 13.5,
                            color: enabled
                                ? AppColors.textDark
                                : AppColors.textGray,
                          ),
                        ),
                        if (enabled) ...[
                          const SizedBox(height: 2),
                          Text(
                            actionHint,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (enabled)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_outward_rounded,
                          size: 16, color: color),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 14,
            color: AppColors.border.withValues(alpha: 0.7),
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FacilityPill extends StatelessWidget {
  final String label;
  const _FacilityPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.tealDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptTile extends StatelessWidget {
  final String name;
  final String description;
  const _DeptTile({required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B6E4F), Color(0xFF1B9E8E)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medical_services_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyBold),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textGray),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REVIEWS — section + write sheet
// ═══════════════════════════════════════════════════════════════════════════

class _ReviewsSection extends StatelessWidget {
  final HospitalDetail hospital;
  final VoidCallback onWriteReview;
  const _ReviewsSection({
    required this.hospital,
    required this.onWriteReview,
  });

  /// Soft visual distribution from average (UI only — not fake reviews).
  List<double> _bars(double rating) {
    // Weights peak near the rounded rating band.
    final peak = rating.clamp(1, 5).round();
    final base = <double>[0.08, 0.12, 0.22, 0.35, 0.55];
    return List.generate(5, (i) {
      final star = 5 - i; // 5..1
      final dist = (star - peak).abs();
      final w = base[i] * (dist == 0 ? 1.35 : dist == 1 ? 0.75 : 0.35);
      return w.clamp(0.05, 1.0);
    });
  }

  String _tone(double rating) {
    if (rating >= 4.5) return 'Outstanding care';
    if (rating >= 4.0) return 'Highly rated';
    if (rating >= 3.0) return 'Good overall';
    if (rating > 0) return 'Mixed feedback';
    return 'No ratings yet';
  }

  @override
  Widget build(BuildContext context) {
    final rating = double.tryParse(hospital.averageRating) ?? 0;
    final bars = _bars(rating <= 0 ? 4 : rating);
    final maxBar = bars.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(Icons.reviews_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Patient reviews',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _tone(rating),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score badge
                    Container(
                      width: 96,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : '—',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8A6A00),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              return Icon(
                                i < rating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFC107),
                                size: 13,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${hospital.totalReviews}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF8A6A00),
                            ),
                          ),
                          Text(
                            'reviews',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF8A6A00).withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Distribution
                    Expanded(
                      child: Column(
                        children: List.generate(5, (i) {
                          final star = 5 - i;
                          final pct = maxBar == 0 ? 0.0 : bars[i] / maxBar;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  child: Text(
                                    '$star',
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.star_rounded,
                                    size: 11, color: Color(0xFFFFC107)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: rating > 0 ? pct : 0.08,
                                      minHeight: 7,
                                      backgroundColor:
                                          const Color(0xFFF0F2F1),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                        Color(0xFFFFC107),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _TrustPill(
                      icon: Icons.verified_user_rounded,
                      label: 'Verified visits',
                    ),
                    const SizedBox(width: 8),
                    _TrustPill(
                      icon: Icons.shield_moon_rounded,
                      label: 'Genuine feedback',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onWriteReview();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B6E4F), Color(0xFF1B9E8E)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Write a review',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your review helps families choose the right care.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 120.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.teal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.tealDark,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final HospitalDetail hospital;
  final Future<void> Function(double rating, String comment) onSubmit;

  const _WriteReviewSheet({
    required this.hospital,
    required this.onSubmit,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  double _rating = 5;
  bool _submitting = false;
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _commentFocus = FocusNode();
  final Set<String> _tags = <String>{};

  static const _aspects = [
    'Care quality',
    'Cleanliness',
    'Staff behaviour',
    'Waiting time',
    'Facilities',
    'Value for money',
  ];

  String get _ratingLabel {
    switch (_rating.round()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      default:
        return 'Excellent';
    }
  }

  Color get _ratingColor {
    switch (_rating.round()) {
      case 1:
        return AppColors.statusRed;
      case 2:
        return AppColors.orange;
      case 3:
        return const Color(0xFFE0A800);
      case 4:
        return AppColors.teal;
      default:
        return AppColors.tealDark;
    }
  }

  @override
  void initState() {
    super.initState();
    _commentFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_commentFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 280), () {
        if (!mounted || !_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _commentFocus.removeListener(_onFocusChange);
    _commentFocus.dispose();
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty && _tags.isEmpty) {
      Get.snackbar(
        'Almost there',
        'Add a short comment or pick a few highlights.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _submitting = true);
    final buffer = StringBuffer();
    if (_tags.isNotEmpty) {
      buffer.writeln('Highlights: ${_tags.join(', ')}');
      buffer.writeln();
    }
    buffer.write(text);
    try {
      await widget.onSubmit(_rating, buffer.toString().trim());
      if (mounted) Get.back();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    // Available height above keyboard — avoids empty gap in the middle.
    final sheetHeight =
        (media.size.height - keyboard).clamp(320.0, media.size.height * 0.92);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: sheetHeight,
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      // Hospital header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 48,
                                height: 48,
                                color: AppColors.teal.withValues(alpha: 0.12),
                                child: widget.hospital.logoUrl != null &&
                                        widget.hospital.logoUrl!.isNotEmpty
                                    ? Image.network(
                                        widget.hospital.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.local_hospital_rounded,
                                          color: AppColors.teal,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.local_hospital_rounded,
                                        color: AppColors.teal,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review your visit',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.hospital.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyBold
                                        .copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stars
                      Text(
                        'How was your experience?',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final active = i < _rating;
                          return IconButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _rating = i + 1.0);
                            },
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            icon: Icon(
                              active
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: active
                                  ? const Color(0xFFFFC107)
                                  : AppColors.border,
                              size: 40,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _ratingColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _ratingLabel,
                            style: TextStyle(
                              color: _ratingColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text('What stood out?', style: AppTextStyles.bodyBold),
                      const SizedBox(height: 4),
                      Text(
                        'Optional — tap to select highlights',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textGray),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _aspects.map((tag) {
                          final selected = _tags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: selected,
                            showCheckmark: true,
                            checkmarkColor: Colors.white,
                            selectedColor: AppColors.tealDark,
                            backgroundColor: const Color(0xFFF3F7F5),
                            side: BorderSide(
                              color: selected
                                  ? Colors.transparent
                                  : AppColors.border.withValues(alpha: 0.8),
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            onSelected: (_) => _toggleTag(tag),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Text('Your review', style: AppTextStyles.bodyBold),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentCtrl,
                        focusNode: _commentFocus,
                        maxLines: 4,
                        minLines: 3,
                        maxLength: 400,
                        textInputAction: TextInputAction.done,
                        onTap: () {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (!mounted || !_scrollCtrl.hasClients) return;
                            _scrollCtrl.animateTo(
                              _scrollCtrl.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          });
                        },
                        style: AppTextStyles.body.copyWith(height: 1.45),
                        decoration: InputDecoration(
                          hintText:
                              'Share details that would help another patient…',
                          hintStyle: AppTextStyles.caption
                              .copyWith(color: AppColors.textGray),
                          filled: true,
                          fillColor: const Color(0xFFF3F7F5),
                          counterStyle: AppTextStyles.caption
                              .copyWith(color: AppColors.textGray),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.teal,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sticky submit — stays above keyboard, no gap
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    (keyboard > 0 ? 10 : 12 + safeBottom),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.tealDark,
                        disabledBackgroundColor:
                            AppColors.teal.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit review',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

