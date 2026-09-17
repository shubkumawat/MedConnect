import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/healora_logo.dart';
import '../../../data/models/family_member_model.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/family_member_controller.dart';
import 'add_family_member_screen.dart';
import 'family_member_detail_view.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final controller = Get.put(FamilyMemberController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getFamilyMemberListAPI(context);
    });
  }

  Future<void> _openAdd() async {
    controller.clearFields();
    await Get.to(() => const AddFamilyMemberScreen());
    if (mounted) controller.getFamilyMemberListAPI(context);
  }

  Future<void> _openDetail(FamilyMember m) async {
    if (m.patientId == null) return;
    controller.getFamilyMemberDetailAPI(context, m.patientId!);
    await Get.to(() => const FamilyMemberDetailScreen());
    if (mounted) controller.getFamilyMemberListAPI(context);
  }

  Future<void> _selectForRecords(FamilyMember m) async {
    final id = m.patientId?.trim();
    if (id == null || id.isEmpty) return;

    final home = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    await home.openRecordsForSelected(patientId: id, member: m);
  }

  String _initials(String? name) {
    final clean = (name ?? '').trim();
    if (clean.isEmpty) return '?';
    final parts =
        clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: Obx(() {
        final loading =
            controller.isLoading.value && controller.familyMemberList.isEmpty;
        final members = controller.familyMemberList.toList();
        // Rebuild when Health Passport selection changes.
        String? selectedId;
        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          home.activePatientIndex.value;
          selectedId = home.selectedPatientId;
        }

        return Column(
          children: [
            _Header(
              topPad: top,
              count: members.length,
              onAdd: _openAdd,
            ),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    )
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: () =>
                          controller.getFamilyMemberListAPI(context),
                      child: members.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.55,
                                  child: _EmptyState(onAdd: _openAdd),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 28),
                              itemCount: members.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, right: 4, bottom: 14),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Care circle',
                                          style:
                                              AppTextStyles.heading3.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${members.length} member${members.length == 1 ? '' : 's'}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textGray,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                final m = members[index - 1];
                                final isSelected = selectedId != null &&
                                    selectedId.isNotEmpty &&
                                    (m.patientId?.trim() ?? '') == selectedId;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _MemberCard(
                                    member: m,
                                    initials: _initials(m.fullName),
                                    isSelected: isSelected,
                                    onTap: () => _openDetail(m),
                                    onOpenDetail: () => _openDetail(m),
                                  )
                                      .animate()
                                      .fadeIn(
                                        delay: (45 * (index - 1)).ms,
                                        duration: 340.ms,
                                      )
                                      .slideY(
                                        begin: 0.05,
                                        end: 0,
                                        delay: (45 * (index - 1)).ms,
                                        curve: Curves.easeOutCubic,
                                      ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  final int count;
  final VoidCallback onAdd;

  const _Header({
    required this.topPad,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 10, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HealoraLogo.chip(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Health profiles for everyone you care for',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(13),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child:
                        Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                _Stat(
                  value: '$count',
                  label: 'Members',
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const _Stat(
                  value: 'Secure',
                  label: 'Records',
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const _Stat(
                  value: '1 tap',
                  label: 'Access',
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool last;

  const _Stat({
    required this.value,
    required this.label,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same compact height/style as details profile card.
class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final String initials;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onOpenDetail;

  const _MemberCard({
    required this.member,
    required this.initials,
    required this.isSelected,
    required this.onTap,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final name = member.fullName?.trim().isNotEmpty == true
        ? member.fullName!
        : 'NA';
    final relation = member.relation?.name ?? 'Family';
    final blood = member.bloodGroup?.trim().isNotEmpty == true
        ? member.bloodGroup!
        : 'NA';
    final age = member.age != null ? '${member.age} yrs' : '—';
    final gender = (member.gender?.trim().isNotEmpty == true)
        ? (member.gender!.capitalizeFirst ?? member.gender!)
        : '—';
    final photo = member.profilePhoto;
    final mobile = member.mobileNumber?.trim() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.tealDark : const Color(0xFFE3EBE7),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealDark.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F2EE),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.28),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photo != null && photo.isNotEmpty
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.tealDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.tealDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                relation.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.tealDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            _AccessChip(member: member),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.tealDark,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'SELECTED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (mobile.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: AppColors.textGray,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  mobile,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textGray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onOpenDetail,
                    tooltip: 'View details',
                    icon: const Icon(Icons.info_outline_rounded,
                        color: AppColors.tealDark),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _ListVital(label: 'Blood', value: blood),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                  _ListVital(label: 'Age', value: age),
                  Container(
                    width: 1,
                    height: 28,
                    color: AppColors.border.withValues(alpha: 0.9),
                  ),
                  _ListVital(label: 'Gender', value: gender),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  final FamilyMember member;
  const _AccessChip({required this.member});

  @override
  Widget build(BuildContext context) {
    final has = member.hasAccess;
    final color = has ? AppColors.tealDark : AppColors.textGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            has ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            member.accessLabel.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListVital extends StatelessWidget {
  final String label;
  final String value;
  const _ListVital({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.tealDark,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                size: 44,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Build your care circle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add family members to manage their health profiles, vitals and emergency details in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.tealDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 20),
                label: const Text(
                  'Add family member',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
