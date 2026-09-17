import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:healaura/app/core/theme/app_colors.dart';
import 'package:healaura/app/core/widgets/healora_logo.dart';
import 'package:healaura/app/core/theme/app_text_theme.dart';
import 'package:healaura/app/data/models/family_member_model.dart';
import 'package:healaura/app/data/services/storage_service.dart';

import '../controllers/family_member_controller.dart';
import 'add_family_member_screen.dart';
import '../../settings/views/menstrual_cycle_screen.dart';

class FamilyMemberDetailScreen extends StatelessWidget {
  const FamilyMemberDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FamilyMemberController>();
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Obx(() {
        final loading = controller.isLoading.value &&
            controller.familyMemberDetail.value == null;
        final member = controller.familyMemberDetail.value;

        if (loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }

        return Column(
          children: [
            _Header(
              topPad: top,
              onBack: () => Get.back(),
              onEdit: member == null
                  ? null
                  : () => _onEdit(context, controller),
              onDelete: member == null
                  ? null
                  : () => _onDelete(context, controller),
            ),
            Expanded(
              child: member == null
                  ? const Center(
                      child: Text(
                        'No details available',
                        style: TextStyle(color: AppColors.textGray),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: () async {
                        if (member.patientId == null) return;
                        await controller.getFamilyMemberDetailAPI(
                            context, member.patientId!);
                        await controller.getFamilyMemberListAPI(context);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: Column(
                          children: [
                            _ProfileHeaderCard(member: member)
                                .animate()
                                .fadeIn(duration: 320.ms)
                                .slideY(begin: 0.04, end: 0),
                            const SizedBox(height: 14),
                            _Section(
                              title: 'Personal information',
                              icon: Icons.person_outline_rounded,
                              rows: [
                                ('Date of birth', _v(member.dateOfBirth)),
                                ('Mobile', _v(member.mobileNumber)),
                                ('Email', _v(member.email)),
                                (
                                  'Height',
                                  member.height != null
                                      ? '${member.height} cm'
                                      : '—'
                                ),
                                (
                                  'Weight',
                                  member.weight != null
                                      ? '${member.weight} kg'
                                      : '—'
                                ),
                                ('Nationality', _v(member.nationality?.name)),
                                ('Marital status', _v(member.maritalStatus)),
                                ('Occupation', _v(member.occupation?.name)),
                                ('Home address', _v(member.homeAddress)),
                              ],
                            ).animate().fadeIn(delay: 70.ms, duration: 300.ms),
                            const SizedBox(height: 12),
                            _MedicalSection(member: member)
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 300.ms),
                            const SizedBox(height: 12),
                            _Section(
                              title: 'Emergency contact',
                              icon: Icons.sos_outlined,
                              accent: AppColors.statusRed,
                              rows: [
                                (
                                  'Name',
                                  _v(member.emergencyContact?.contactName)
                                ),
                                (
                                  'Relation',
                                  _v(member.emergencyContact?.relation)
                                ),
                                (
                                  'Phone',
                                  _v(member.emergencyContact?.phoneNumber)
                                ),
                              ],
                            ).animate().fadeIn(delay: 130.ms, duration: 300.ms),
                            const SizedBox(height: 12),
                            _Section(
                              title: 'Insurance',
                              icon: Icons.verified_user_outlined,
                              accent: AppColors.accentBlue,
                              rows: [
                                ('Provider', _v(member.insurance?.provider)),
                                (
                                  'Policy number',
                                  _v(member.insurance?.policyNumber)
                                ),
                                ('Expiry', _v(member.insurance?.expiryDate)),
                              ],
                            ).animate().fadeIn(delay: 160.ms, duration: 300.ms),
                            const SizedBox(height: 12),
                            _AccessStatusCard(controller: controller)
                                .animate()
                                .fadeIn(delay: 180.ms, duration: 300.ms),
                            if (member.isFemale) ...[
                              const SizedBox(height: 12),
                              _CycleRemindersCard(member: member),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            if (member != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Obx(() {
                  final detail = controller.familyMemberDetail.value ?? member;
                  final hasAccess = detail.hasAccess;
                  final label = hasAccess ? 'Revoke Access' : 'Give Access';
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              final id = detail.patientId;
                              if (id == null) return;
                              if (hasAccess) {
                                await controller.giveAccessAPI(
                                  context,
                                  id,
                                  type: 'remove',
                                );
                              } else {
                                await controller.giveAccessAPI(context, id);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: hasAccess
                            ? AppColors.statusRed
                            : AppColors.tealDark,
                        disabledBackgroundColor:
                            AppColors.tealDark.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  hasAccess
                                      ? Icons.lock_rounded
                                      : Icons.lock_open_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ),
          ],
        );
      }),
    );
  }

  static String _v(String? s) {
    if (s == null || s.trim().isEmpty) return '—';
    return s.trim();
  }

  Future<void> _onEdit(
      BuildContext context, FamilyMemberController controller) async {
    final member = controller.familyMemberDetail.value;
    if (member == null) return;
    controller.isUpdateMode.value = true;
    controller.currentPatientId = member.patientId;
    await Get.to(() => const AddFamilyMemberScreen());
    if (controller.currentPatientId != null && context.mounted) {
      controller.getFamilyMemberDetailAPI(
          context, controller.currentPatientId!);
      controller.getFamilyMemberListAPI(context);
    }
  }

  Future<void> _onDelete(
      BuildContext context, FamilyMemberController controller) async {
    final accessType =
        await StorageService().getString(StorageService.accessType);
    if (accessType == '2') {
      Get.snackbar(
        'Access Restricted',
        "You don't have permission to delete patient details.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Remove member?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        content: const Text(
          'This will permanently remove this family member from your care circle.',
          style: TextStyle(color: AppColors.textGray, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Get.back();
              final id = controller.familyMemberDetail.value?.patientId;
              if (id == null) return;
              controller.deleteFamilyMember(context, id, () => Get.back());
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _Header({
    required this.topPad,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          _HBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          const HealoraLogo.chip(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Details',
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Complete health profile',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            _HBtn(icon: Icons.edit_outlined, onTap: onEdit!),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            _HBtn(
              icon: Icons.delete_outline_rounded,
              onTap: onDelete!,
              softRed: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _HBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool softRed;

  const _HBtn({
    required this.icon,
    required this.onTap,
    this.softRed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 18,
            color: softRed ? const Color(0xFFFFB4B4) : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Compact professional profile header — avatar + identity + vitals in one card.
class _ProfileHeaderCard extends StatelessWidget {
  final FamilyMember member;
  const _ProfileHeaderCard({required this.member});

  String get _initials {
    final name = (member.fullName ?? '').trim();
    if (name.isEmpty) return '?';
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = member.fullName?.trim().isNotEmpty == true
        ? member.fullName!
        : 'NA';
    final relation = member.relation?.name ?? 'Family member';
    final mobile = member.mobileNumber?.trim() ?? '';
    final photo = member.profilePhoto;
    final blood = member.bloodGroup?.trim().isNotEmpty == true
        ? member.bloodGroup!
        : 'NA';
    final age = member.age != null ? '${member.age} yrs' : '—';
    final gender = (member.gender?.trim().isNotEmpty == true)
        ? (member.gender!.capitalizeFirst ?? member.gender!)
        : '—';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE7)),
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
                              _initials,
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
                            _initials,
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
                          Builder(
                            builder: (_) {
                              final has = member.hasAccess;
                              final color = has
                                  ? AppColors.tealDark
                                  : AppColors.textGray;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.28)),
                                ),
                                child: Text(
                                  member.accessLabel.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              );
                            },
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
                _VitalCell(label: 'Blood', value: blood),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border.withValues(alpha: 0.9),
                ),
                _VitalCell(label: 'Age', value: age),
                Container(
                  width: 1,
                  height: 28,
                  color: AppColors.border.withValues(alpha: 0.9),
                ),
                _VitalCell(label: 'Gender', value: gender),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalCell extends StatelessWidget {
  final String label;
  final String value;
  const _VitalCell({required this.label, required this.value});

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

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<(String, String)> rows;

  const _Section({
    required this.title,
    required this.icon,
    required this.rows,
    this.accent = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map((e) {
            final last = e.key == rows.length - 1;
            return _Row(label: e.value.$1, value: e.value.$2, last: last);
          }),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _Row({
    required this.label,
    required this.value,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: last ? 10 : 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F4F2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalSection extends StatelessWidget {
  final FamilyMember member;
  const _MedicalSection({required this.member});

  @override
  Widget build(BuildContext context) {
    final allergies = member.medical?.allergies
            ?.map((e) => e.allergyName ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final meds = member.medical?.currentMedications ?? [];
    final risks = (member.medical?.riskFactorLabels?.isNotEmpty ?? false)
        ? member.medical!.riskFactorLabels!
        : (member.medical?.riskFactors ?? []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.medical_information_outlined,
                  color: AppColors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Medical status',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: 'Chronic',
                yes: member.medical?.chronicDisease == true,
              ),
              _StatusChip(
                label: 'Handicapped',
                yes: member.medical?.physicallyHandicapped == true,
              ),
              _StatusChip(
                label: 'Organ donor',
                yes: member.medical?.organDonor == true,
              ),
            ],
          ),
          if (member.medical?.physicallyHandicapped == true &&
              (member.medical?.disabilityType?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            _Row(
              label: 'Disability type',
              value: member.medical!.disabilityType!,
              last: true,
            ),
          ],
          const SizedBox(height: 14),
          _Chips(
              title: 'Allergies',
              items: allergies,
              color: AppColors.statusRed),
          const SizedBox(height: 12),
          _Chips(
              title: 'Risk factors',
              items: risks,
              color: AppColors.orange),
          const SizedBox(height: 12),
          _Chips(title: 'Medications', items: meds, color: AppColors.teal),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool yes;
  const _StatusChip({required this.label, required this.yes});

  @override
  Widget build(BuildContext context) {
    final color = yes ? AppColors.teal : AppColors.textGray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: yes
            ? AppColors.teal.withValues(alpha: 0.1)
            : const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: yes
              ? AppColors.teal.withValues(alpha: 0.25)
              : const Color(0xFFE3EBE7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            yes ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '$label · ${yes ? 'Yes' : 'No'}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;

  const _Chips({
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.isEmpty
              ? const [
                  Text(
                    'None recorded',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textGray),
                  ),
                ]
              : items
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _AccessStatusCard extends StatelessWidget {
  final FamilyMemberController controller;
  const _AccessStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final member = controller.familyMemberDetail.value;
      final name = member?.fullName?.trim().isNotEmpty == true
          ? member!.fullName!
          : 'this member';
      final has = member?.hasAccess ?? false;
      final statusColor = has ? AppColors.tealDark : AppColors.textGray;
      final statusText = has ? 'Access given' : 'No access yet';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3EBE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    has ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record access',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    has ? 'ACTIVE' : 'OFF',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              has
                  ? '$name can currently view shared health records.'
                  : 'Share $name’s health records securely with Give Access.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CycleRemindersCard extends StatelessWidget {
  final FamilyMember member;
  const _CycleRemindersCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.to(() => MenstrualCycleScreen(
              patientId: member.patientId,
              patientName: member.fullName,
            )),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_outlined,
                    color: AppColors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cycle reminders',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Set period alerts for this member',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textGray),
            ],
          ),
        ),
      ),
    );
  }
}


