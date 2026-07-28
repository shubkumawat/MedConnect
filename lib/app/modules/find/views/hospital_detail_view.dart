import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/find_controller.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';

class HospitalDetailView extends StatefulWidget {
  final String hospitalId;
  HospitalDetailView({super.key, required this.hospitalId});

  @override
  State<HospitalDetailView> createState() => _HospitalDetailViewState();
}

class _HospitalDetailViewState extends State<HospitalDetailView> {
  final FindController controller = Get.find<FindController>();

  // ---------------- LAUNCH HELPERS ----------------
  Future<void> _launch(Uri uri) async {
    final ok = await canLaunchUrl(uri);
    if (ok) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Couldn't open", "No app found to handle this action.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _callPhone(String phone) => _launch(Uri(scheme: 'tel', path: phone));

  Future<void> _sendEmail(String email) => _launch(Uri(scheme: 'mailto', path: email));

  Future<void> _openWebsite(String url) {
    final hasScheme = url.startsWith('http://') || url.startsWith('https://');
    return _launch(Uri.parse(hasScheme ? url : 'https://$url'));
  }

  Future<void> _openDirections(String address) {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    return _launch(uri);
  }

  void _showReviewDialog(BuildContext context, String hospitalId) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Write a Review${widget.hospitalId}", style: AppTextStyles.heading3),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => selectedRating = index + 1.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          index < selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFFFC107),
                          size: 21,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: "Share your experience...",
                    hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted.withOpacity(0.5)),
                    filled: true,
                    fillColor: AppColors.textFieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.fetchHospitalDetail(widget.hospitalId);
              Get.back();},
            child: Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.trim().isEmpty) {
                Get.snackbar("Error", "Please enter a comment",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white);
                return;
              }
              await controller.submitReview(
                id: widget.hospitalId,
                rating: selectedRating,
                comment: commentController.text,
                isHospital: true,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Submit", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fluttertoast.showToast(msg: "Loading...${widget.hospitalId}");

    controller.fetchHospitalDetail(widget.hospitalId);
    return Scaffold(
      backgroundColor: AppColors.bgDeepNavy,
      body: Obx(() {
        if (controller.isDetailLoading.value) {
          return const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          );
        }

        final hospital = controller.hospitalDetail.value;
        if (hospital == null) {
          return const Center(
            key: ValueKey('empty'),
            child: Text("Hospital not found"),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _buildContent(context, hospital),
        );
      }),
    );
  }

  Widget _buildContent(BuildContext context, hospital) {
    return Stack(
      key: ValueKey(hospital.name),
      children: [
        CustomScrollView(
          slivers: [
            // ---------------- HERO ----------------
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    hospital.bannerUrl != null
                        ? Image.network(hospital.bannerUrl!, fit: BoxFit.cover)
                        : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.tealDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.local_hospital_rounded,
                            size: 72, color: Colors.white38),
                      ),
                    ),
                    // Scrim so title/badges stay legible over any photo
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- FLOATING INFO CARD ----------------
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 38),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(hospital.name,
                                    style: AppTextStyles.heading2.copyWith(fontSize: 22)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hospital.hospitalType.toUpperCase(),
                                    style: AppTextStyles.captionBold
                                        .copyWith(color: AppColors.orange, letterSpacing: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _RatingBadge(rating: hospital.averageRating),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        text: hospital.address,
                        onTap: () => _openDirections(hospital.address),
                      ),
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        text: hospital.phone,
                        onTap: () => _callPhone(hospital.phone),
                      ),
                      _InfoRow(
                        icon: Icons.email_rounded,
                        text: hospital.email,
                        onTap: () => _sendEmail(hospital.email),
                      ),
                      if (hospital.website != null)
                        _InfoRow(
                          icon: Icons.language_rounded,
                          text: hospital.website!,
                          isLast: true,
                          onTap: () => _openWebsite(hospital.website!),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ---------------- QUICK ACTIONS ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.call_rounded,
                        label: "Call",
                        color: AppColors.teal,
                        onTap: () => _callPhone(hospital.phone),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.directions_rounded,
                        label: "Directions",
                        color: AppColors.primary,
                        onTap: () => _openDirections(hospital.address),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.email_rounded,
                        label: "Email",
                        color: AppColors.orange,
                        onTap: () => _sendEmail(hospital.email),
                      ),
                    ),
                    if (hospital.website != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.language_rounded,
                          label: "Website",
                          color: const Color(0xFF7C5CFC),
                          onTap: () => _openWebsite(hospital.website!),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ---------------- ABOUT ----------------
            SliverToBoxAdapter(
              child: _Section(
                title: "About",
                child: Text(
                  hospital.about,
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted, height: 1.5),
                ),
              ),
            ),

            // ---------------- FACILITIES ----------------
            SliverToBoxAdapter(
              child: _Section(
                title: "Facilities",
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: hospital.facilities
                      .map<Widget>((f) => _FacilityChip(label: f.name))
                      .toList(),
                ),
              ),
            ),

            // ---------------- DEPARTMENTS ----------------
            SliverToBoxAdapter(
              child: _Section(
                title: "Departments",
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: hospital.departments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final dept = hospital.departments[index];
                    return _DepartmentCard(name: dept.name, description: dept.description);
                  },
                ),
              ),
            ),

            // ---------------- REVIEWS SECTION ----------------
            SliverToBoxAdapter(
              child: _Section(
                title: "Reviews",
                child: McCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hospital.averageRating,
                                  style: AppTextStyles.heading1.copyWith(fontSize: 32)),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (index) {
                                  double ratingValue = double.tryParse(hospital.averageRating) ?? 0;
                                  return Icon(
                                    index < ratingValue.floor()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: const Color(0xFFFFC107),
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text("${hospital.totalReviews} Reviews",
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                          const Spacer(),
                          CustomPrimaryButton(
                            text: "Write a Review",
                            width: 140,
                            height: 40,
                            onTap: () => _showReviewDialog(context, hospital.hospitalId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Space so content clears the persistent bottom bar
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),

        // ---------------- PERSISTENT EMERGENCY BAR ----------------
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 14 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CustomPrimaryButton(
              text: "Emergency Call: ${hospital.emergencyPhone}",
              color: AppColors.statusRed,
              onTap: () => _callPhone(hospital.emergencyPhone),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Small building blocks
// ============================================================

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withOpacity(0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
          const SizedBox(width: 4),
          Text(rating, style: AppTextStyles.bodyBold.copyWith(color: const Color(0xFF9E7700))),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.85), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.captionBold),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

class _FacilityChip extends StatelessWidget {
  final String label;
  const _FacilityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.teal.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.captionBold),
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final String name;
  final String description;
  const _DepartmentCard({required this.name, required this.description});

  @override
  Widget build(BuildContext context) {
    return McCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(description,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;
  final VoidCallback? onTap;
  const _InfoRow({required this.icon, required this.text, this.isLast = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 14))),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}