import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/family_member_model.dart';
import '../../../data/models/video_model.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../family/controllers/family_member_controller.dart';
import '../../family/views/add_family_member_screen.dart';
import '../controllers/home_controller.dart';
import 'bmi_calculator_screen.dart';
import 'notifications_screen.dart';
import 'qr_view.dart';
import 'video_series_screen.dart';

/// Home redesigned around a clear care flow:
/// 1) Who am I caring for?  → swipeable Health Passport
/// 2) What needs attention? → Today's Care
/// 3) Where can I go next?  → Quick Jump
/// 4) What can I learn?     → Learn hub (continue + topics)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController controller;
  late final PageController _passportPage;
  Worker? _passportIndexWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.put(HomeController());
    _passportPage = PageController(viewportFraction: 0.88);
    // Keep PageView on the selected passport card (restore / programmatic select).
    _passportIndexWorker = ever<int>(controller.activePatientIndex, (i) {
      if (!_passportPage.hasClients) return;
      final page = _passportPage.page?.round();
      if (page == i) return;
      _passportPage.jumpToPage(i);
    });
  }

  @override
  void dispose() {
    _passportIndexWorker?.dispose();
    _passportPage.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _onRefresh() async {
    await controller.fetchFamilyMembers();
    await Future.wait([
      controller.fetchVideoTopics(),
      controller.fetchTrendingVideos(),
      controller.loadHistoryLists(),
    ]);
  }

  Future<void> _addMember() async {
    final familyController = Get.find<FamilyMemberController>();
    familyController.clearFields();
    final result = await Get.to(() => const AddFamilyMemberScreen());
    if (result == true) {
      await controller.fetchFamilyMembers();
      if (controller.patients.isNotEmpty) {
        final last = controller.patients.length - 1;
        controller.changePatient(last);
        if (_passportPage.hasClients) {
          _passportPage.animateToPage(
            last,
            duration: 320.ms,
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  void _jumpTab(int index) {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: RefreshIndicator(
        color: AppColors.teal,
        displacement: 40,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _TopBar(topPad: top, greeting: _greeting)),
            SliverToBoxAdapter(
              child: _PassportSection(
                controller: controller,
                pageController: _passportPage,
                onAdd: _addMember,
                onSelectMember: (index) async {
                  if (_passportPage.hasClients) {
                    await _passportPage.animateToPage(
                      index,
                      duration: 280.ms,
                      curve: Curves.easeOutCubic,
                    );
                  }
                  await controller.openRecordsForSelected(index: index);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TodaysCare(controller: controller)
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 420.ms)
                        .slideY(begin: 0.06, end: 0),
                    const SizedBox(height: 18),
                    _BmiCalculatorCard(
                      onTap: () => Get.to(() => const BmiCalculatorScreen()),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 420.ms)
                        .slideY(begin: 0.06, end: 0),
                    const SizedBox(height: 22),
                    _QuickJump(
                      onRecords: () => _jumpTab(1),
                      onFind: () => _jumpTab(2),
                      onFamily: () => _jumpTab(3),
                      onVideos: () => Get.to(() => const VideoSeriesScreen()),
                    )
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 420.ms)
                        .slideY(begin: 0.06, end: 0),
                    const SizedBox(height: 26),
                    _LearnHub(controller: controller)
                        .animate()
                        .fadeIn(delay: 240.ms, duration: 420.ms),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final double topPad;
  final String greeting;
  const _TopBar({required this.topPad, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 10, 16, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo/ic_logo_icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'HealAura',
                  style: AppTextStyles.heading3.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          _IconBtn(
            icon: Icons.notifications_none_rounded,
            onTap: () => Get.to(() => const NotificationsScreen()),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOut);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.tealDark, size: 22),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEALTH PASSPORT — swipe between family members
// ═══════════════════════════════════════════════════════════════════════════

class _PassportSection extends StatelessWidget {
  final HomeController controller;
  final PageController pageController;
  final VoidCallback onAdd;
  final ValueChanged<int> onSelectMember;

  const _PassportSection({
    required this.controller,
    required this.pageController,
    required this.onAdd,
    required this.onSelectMember,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
          child: Row(
            children: [
              Text('Health Passport', style: AppTextStyles.heading3),
              const Spacer(),
              // GestureDetector(
              //   onTap: onAdd,
              //   child: Row(
              //     children: [
              //       Icon(Icons.person_add_alt_1_rounded,
              //           size: 16, color: AppColors.teal),
              //       const SizedBox(width: 4),
              //       Text(
              //         'Add member',
              //         style: AppTextStyles.tealLabel.copyWith(fontSize: 12),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 268,
          child: Obx(() {
            if (controller.isLoading.value && controller.patients.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.teal),
              );
            }
            if (controller.patients.isEmpty) {
              return _EmptyPassport(onAdd: onAdd);
            }
            return PageView.builder(
              controller: pageController,
              itemCount: controller.patients.length,
              onPageChanged: controller.changePatient,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: pageController,
                  builder: (context, child) {
                    double scale = 1;
                    if (pageController.position.haveDimensions) {
                      final page = pageController.page ?? index.toDouble();
                      scale = (1 - (page - index).abs() * 0.06).clamp(0.9, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Obx(() => _PassportCard(
                    patient: controller.patients[index],
                    initials: controller.getInitials(
                      controller.patients[index].fullName ?? '',
                    ),
                    isSelected: controller.activePatientIndex.value == index,
                    onTap: () => onSelectMember(index),
                  )),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final n = controller.patients.length;
          if (n <= 1) return const SizedBox(height: 6);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(n, (i) {
              final active = controller.activePatientIndex.value == i;
              return AnimatedContainer(
                duration: 220.ms,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.teal : AppColors.teal.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        }),
      ],
    )
        .animate()
        .fadeIn(delay: 60.ms, duration: 450.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _EmptyPassport extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPassport({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onAdd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.35),
              width: 1.5,
            ),
            color: Colors.white,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.teal, size: 28),
                ),
                const SizedBox(height: 12),
                Text('Add your first family member', style: AppTextStyles.bodyBold),
                const SizedBox(height: 4),
                Text(
                  'Build their digital health passport',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  final FamilyMember patient;
  final String initials;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PassportCard({
    required this.patient,
    required this.initials,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blood = patient.bloodGroup?.trim().isNotEmpty == true
        ? patient.bloodGroup!
        : '--';
    final age = patient.age != null ? '${patient.age}' : '--';
    final gender = (patient.gender?.trim().isNotEmpty == true)
        ? (patient.gender!.capitalizeFirst ?? patient.gender!)
        : '--';
    final meds = patient.medical?.currentMedications?.length ?? 0;
    final diseases = patient.medical?.chronicDisease == true ? 1 : 0;
    final isMe = patient.isSelf;
    // Me from profile; others keep API relation (Son / Daughter / …) like before.
    final relation = isMe
        ? 'Me'
        : (patient.relation?.name ?? 'Member');
    final photo = patient.profilePhoto?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B6E4F).withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Base gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Soft orbs
              Positioned(
                right: -40,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasPhoto
                              ? Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
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
                                      fontSize: 15,
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
                                patient.fullName ?? (isMe ? 'You' : 'Guest'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading2.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.28)
                                          : Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isMe
                                          ? Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.45))
                                          : null,
                                    ),
                                    child: Text(
                                      relation.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFC857),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'SELECTED',
                                        style: TextStyle(
                                          color: Color(0xFF0A5C45),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _QrFab(
                          onTap: () => Get.to(
                            () => QrScreen(
                              patientName: patient.fullName ?? 'Patient',
                              patientId: patient.patientId,
                              profilePhoto: patient.profilePhoto,
                              initials: initials,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Vitals strip
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              _PassportMetric(label: 'Blood', value: blood),
                              _PassportMetric(
                                  label: 'Age',
                                  value: age == '--' ? '--' : '$age yrs'),
                              _PassportMetric(label: 'Gender', value: gender),
                              _PassportMetric(label: 'Meds', value: '$meds'),
                              _PassportMetric(
                                  label: 'Conditions',
                                  value: '$diseases',
                                  last: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.swipe_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSelected
                              ? 'Tap card → open records'
                              : 'Tap to select & open records',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Show QR',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ],
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

class _PassportMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _PassportMetric({
    required this.label,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrFab extends StatelessWidget {
  final VoidCallback onTap;
  const _QrFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(Icons.qr_code_2_rounded, color: AppColors.tealDark, size: 26),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1600.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TODAY'S CARE — attention timeline
// ═══════════════════════════════════════════════════════════════════════════

class _TodaysCare extends StatelessWidget {
  final HomeController controller;
  const _TodaysCare({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = <_CareItem>[];
      if (controller.showMedReminders.value) {
        items.add(
          const _CareItem(
            title: 'Paracetamol',
            meta: '10:00 AM · Dose due',
            icon: Icons.medication_liquid_rounded,
            accent: AppColors.orange,
            tag: 'MED',
          ),
        );
      }
      if (controller.showVacReminders.value) {
        items.add(
          const _CareItem(
            title: 'Flu Shot',
            meta: 'Next week · Clinic',
            icon: Icons.vaccines_rounded,
            accent: AppColors.teal,
            tag: 'VAX',
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today\'s Care', style: AppTextStyles.heading3),
              const Spacer(),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length} due',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.orange,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No reminders for today — you\'re all clear.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textGray),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _CareTicket(item: items[i]),
              ),
            ),
        ],
      );
    });
  }
}

class _CareItem {
  final String title;
  final String meta;
  final IconData icon;
  final Color accent;
  final String tag;
  const _CareItem({
    required this.title,
    required this.meta,
    required this.icon,
    required this.accent,
    required this.tag,
  });
}

class _CareTicket extends StatelessWidget {
  final _CareItem item;
  const _CareTicket({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: item.accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, color: item.accent, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.tag,
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(item.title, style: AppTextStyles.bodyBold, maxLines: 1),
          const SizedBox(height: 2),
          Text(
            item.meta,
            style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// QUICK JUMP
// ═══════════════════════════════════════════════════════════════════════════

class _QuickJump extends StatelessWidget {
  final VoidCallback onRecords;
  final VoidCallback onFind;
  final VoidCallback onFamily;
  final VoidCallback onVideos;

  const _QuickJump({
    required this.onRecords,
    required this.onFind,
    required this.onFamily,
    required this.onVideos,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _JumpItem('Records', Icons.folder_shared_rounded, const Color(0xFF0B6E4F), onRecords),
      _JumpItem('Find care', Icons.local_hospital_rounded, AppColors.teal, onFind),
      _JumpItem('Family', Icons.groups_rounded, AppColors.orange, onFamily),
      _JumpItem('Videos', Icons.play_circle_rounded, AppColors.accentBlue, onVideos),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Jump', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map(
                (a) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
                    child: _JumpTile(item: a),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _JumpItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _JumpItem(this.label, this.icon, this.color, this.onTap);
}

class _JumpTile extends StatelessWidget {
  final _JumpItem item;
  const _JumpTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: item.color.withValues(alpha: 0.14)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BMI CALCULATOR ENTRY
// ═══════════════════════════════════════════════════════════════════════════

class _BmiCalculatorCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BmiCalculatorCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
            gradient: LinearGradient(
              colors: [
                AppColors.teal.withValues(alpha: 0.08),
                Colors.white,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tealDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.monitor_weight_outlined,
                    color: AppColors.tealDark, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI Calculator',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check your body mass index in seconds',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tealDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Calculate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LEARN HUB
// ═══════════════════════════════════════════════════════════════════════════

class _LearnHub extends StatelessWidget {
  final HomeController controller;
  const _LearnHub({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Learn', style: AppTextStyles.heading3),
            const Spacer(),
            GestureDetector(
              onTap: () => Get.to(() => const VideoSeriesScreen()),
              child: Text(
                'Browse all',
                style: AppTextStyles.tealLabel.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Short health explainers for your family',
          style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
        ),
        const SizedBox(height: 14),

        // Featured continue watching
        Obx(() {
          if (controller.continueWatching.isEmpty) return const SizedBox.shrink();
          final v = controller.continueWatching.first;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _FeaturedContinue(video: v),
          );
        }),

        // Topics
        SizedBox(
          height: 38,
          child: Obx(() {
            if (controller.isTopicsLoading.value) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                ),
              );
            }
            final labels = controller.topicChipLabels;
            final selected = controller.selectedTopicIndex.value;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: labels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = selected == i;
                return GestureDetector(
                  onTap: () => controller.changeTopic(i),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.tealDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : AppColors.border.withValues(alpha: 0.9),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: AppTextStyles.captionBold.copyWith(
                        color: active ? Colors.white : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 14),

        // Horizontal video rail
        Obx(() {
          if (controller.isVideoLoading.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
            );
          }
          if (controller.videos.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No videos for this topic yet',
                style: AppTextStyles.body.copyWith(color: AppColors.textGray),
              ),
            );
          }
          return SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _VideoRailCard(video: controller.videos[i])
                  .animate()
                  .fadeIn(delay: (50 * i).ms, duration: 320.ms)
                  .slideX(begin: 0.05, end: 0),
            ),
          );
        }),
      ],
    );
  }
}

class _FeaturedContinue extends StatelessWidget {
  final VideoModel video;
  const _FeaturedContinue({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const VideoSeriesScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                video.thumbnail ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.tealDark,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CONTINUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${video.presenterName} · ${video.formattedDuration}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoRailCard extends StatelessWidget {
  final VideoModel video;
  const _VideoRailCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const VideoSeriesScreen()),
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnail ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(Icons.play_circle_outline, color: AppColors.teal),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          video.formattedDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.textDark,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              video.formattedViews,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGray,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
