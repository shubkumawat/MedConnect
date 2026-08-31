import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../../../data/models/disease_response_model.dart';
import '../../../data/models/medical_record_model.dart';
import '../controllers/records_controller.dart';
import 'add_medication_screen.dart';
import 'add_disease_screen.dart';
import 'disease_detail_screen.dart';
import 'ai_prescription_screen.dart';
import 'medication_detail_screen.dart';
import '../../../data/models/family_member_model.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/views/qr_view.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RecordsController controller = Get.put(RecordsController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
    if (_tabController.index == 1) {
      controller.fetchCurrentMedications();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _openQr() {
    final members = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().patients.toList()
        : <FamilyMember>[];
    final selectedId = controller.selectedPatientId.value.trim();
    FamilyMember? selected;
    for (final m in members) {
      if ((m.patientId ?? '').trim() == selectedId) {
        selected = m;
        break;
      }
    }
    selected ??= members.isNotEmpty ? members.first : null;
    final isSelf = selected?.isSelf ?? selectedId.isEmpty;

    Get.to(() => QrScreen(
          patientName: controller.selectedPatientName.value,
          patientId: selectedId.isEmpty ? null : selectedId,
          profilePhoto: controller.selectedPatientPhoto.value.isEmpty
              ? null
              : controller.selectedPatientPhoto.value,
          isSelf: isSelf,
        ));
  }

  void _showMemberSwitcher() {
    final members = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().patients.toList()
        : <FamilyMember>[];
    if (members.isEmpty) {
      Get.snackbar(
        'Members',
        'No members found. Open Home to load Health Passport.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.orange,
        colorText: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MemberSwitcherSheet(
        members: members,
        selectedPatientId: controller.selectedPatientId.value,
        onSelect: (member, index) async {
          Navigator.pop(context);
          await controller.selectMember(member, index: index);
        },
      ),
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'med':
        return Icons.medication_rounded;
      case 'qr':
        return Icons.qr_code_rounded;
      case 'doc':
        return Icons.description_rounded;
      case 'hosp':
        return Icons.local_hospital_rounded;
      case 'vac':
        return Icons.vaccines_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: Column(
        children: [
          Obx(() => _RecordsHeader(
                topPad: top,
                patientName: controller.selectedPatientName.value,
                patientRelation: controller.selectedPatientRelation.value,
                patientPhoto: controller.selectedPatientPhoto.value,
                isSelf: controller.selectedIsSelf.value,
                diseaseCount: controller.diseases.length,
                medCount: controller.medications.length,
                eventCount: controller.timelineEvents.length,
                tabIndex: _tabController.index,
                onTabSelected: (i) {
                  _tabController.animateTo(i);
                  setState(() {});
                },
                onSwitchMember: _showMemberSwitcher,
                onAdd: () => _showAddSheet(context),
              )),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DiseasesTab(controller: controller),
                _MedicationsTab(
                  controller: controller,
                  onConfirmDelete: _confirmDeleteCurrentMedication,
                ),
                _TimelineTab(
                  controller: controller,
                  eventIcon: _eventIcon,
                  onEmptyAdd: () => _showAddSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: _RecordsFab(onTap: () => _showAddSheet(context)),
      ),
    );
  }

  Future<void> _confirmDeleteCurrentMedication(Medication med) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medication'),
        content: Text('Remove "${med.name}" from current medications?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await controller.deleteMedication(
        medicationUuid: med.id,
        isCurrentMedication: true,
      );
      Get.snackbar(
        ok ? 'Success' : 'Error',
        ok ? 'Medication deleted' : 'Failed to delete medication',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ok ? AppColors.teal : AppColors.statusRed,
        colorText: Colors.white,
      );
    }
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _PremiumActionSheet(
        title: 'Add to records',
        subtitle: 'Build a complete, clinic-ready health history',
        options: [
          _SheetAction(
            step: '01',
            icon: Icons.monitor_heart_outlined,
            label: 'Add Disease',
            subtitle: 'Condition, status & diagnosis details',
            color: AppColors.orange,
            onTap: () {
              Navigator.pop(context);
              Get.to(() => AddDiseaseScreen());
            },
          ),
          // _SheetAction(
          //   step: '02',
          //   icon: Icons.medication_outlined,
          //   label: 'Add Medication',
          //   subtitle: 'Current medicines, dosage & reminders',
          //   color: AppColors.tealDark,
          //   onTap: () {
          //     Navigator.pop(context);
          //     Get.to(() =>
          //         const AddMedicationScreen(isCurrentMedication: true));
          //   },
          // ),
          _SheetAction(
            step: '02 ',
            icon: Icons.document_scanner_outlined,
            label: 'Scan Prescription (AI)',
            subtitle: 'Extract medicines from a photo instantly',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context);
              Get.to(() => AiPrescriptionScreen());
            },
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _RecordsHeader extends StatelessWidget {
  final double topPad;
  final String patientName;
  final String patientRelation;
  final String patientPhoto;
  final bool isSelf;
  final int diseaseCount;
  final int medCount;
  final int eventCount;
  final int tabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSwitchMember;
  final VoidCallback onAdd;

  const _RecordsHeader({
    required this.topPad,
    required this.patientName,
    required this.patientRelation,
    required this.patientPhoto,
    required this.isSelf,
    required this.diseaseCount,
    required this.medCount,
    required this.eventCount,
    required this.tabIndex,
    required this.onTabSelected,
    required this.onSwitchMember,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = patientPhoto.isNotEmpty;
    final initials = patientName.trim().isEmpty
        ? '?'
        : patientName
            .trim()
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 16),
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
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
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
                      'Health Records',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Viewing selected member',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon: Icons.add_rounded,
                onTap: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSwitchMember,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasPhoto
                          ? Image.network(patientPhoto, fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Center(
                                    child: Text(initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800)),
                                  ))
                          : Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
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
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  patientRelation.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC857)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isSelf ? 'YOU · SELECTED' : 'SELECTED',
                                  style: const TextStyle(
                                    color: Color(0xFF0A5C45),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.swap_horiz_rounded,
                        color: Colors.white.withValues(alpha: 0.9)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                _Stat(value: '$diseaseCount', label: 'Diseases'),
                _vDiv(),
                _Stat(value: '$medCount', label: 'Medicines'),
                _vDiv(),
                _Stat(value: '$eventCount', label: 'Events'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TabPill(
                  label: 'Diseases',
                  selected: tabIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _TabPill(
                  label: 'Medications',
                  selected: tabIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                _TabPill(
                  label: 'Timeline',
                  selected: tabIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDiv() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withValues(alpha: 0.2),
      );
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _MemberSwitcherSheet extends StatelessWidget {
  final List<FamilyMember> members;
  final String selectedPatientId;
  final void Function(FamilyMember member, int index) onSelect;

  const _MemberSwitcherSheet({
    required this.members,
    required this.selectedPatientId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select member',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Records will load for the selected person',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: members.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = members[i];
                final id = m.patientId?.trim() ?? '';
                final selected = id.isNotEmpty && id == selectedPatientId;
                final relation =
                    m.isSelf ? 'Me' : (m.relation?.name ?? 'Member');
                final photo = m.profilePhoto?.trim() ?? '';
                final name = m.fullName?.trim().isNotEmpty == true
                    ? m.fullName!.trim()
                    : (m.isSelf ? 'You' : 'Member');
                final initials = name
                    .split(RegExp(r'\s+'))
                    .where((e) => e.isNotEmpty)
                    .take(2)
                    .map((e) => e[0].toUpperCase())
                    .join();

                return Material(
                  color: selected
                      ? const Color(0xFFE8F2EE)
                      : const Color(0xFFF7FAF8),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onSelect(m, i),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.tealDark
                              : const Color(0xFFE3EBE7),
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal.withValues(alpha: 0.12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: photo.isNotEmpty
                                ? Image.network(photo, fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                          child: Text(initials,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.tealDark)),
                                        ))
                                : Center(
                                    child: Text(initials,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.tealDark)),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(relation,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          if (selected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.tealDark,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
  const _Stat({required this.value, required this.label});

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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.tealDark : Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tabs ─────────────────────────────────────────────────────────────────────

class _DiseasesTab extends StatelessWidget {
  final RecordsController controller;
  const _DiseasesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.diseases.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        );
      }
      if (controller.diseases.isEmpty) {
        return _EmptyState(
          icon: Icons.monitor_heart_outlined,
          title: 'No conditions yet',
          subtitle:
              'Add diseases and health conditions to build a complete medical history.',
          cta: 'Add Disease',
          onTap: () => Get.to(() => AddDiseaseScreen()),
        );
      }
      return RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => controller.fetchDiseases(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          itemCount: controller.diseases.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Your conditions',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.diseases.length} recorded',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            final d = controller.diseases[index - 1];
            final heroTag = 'disease_${d.uuid}';
            return Dismissible(
              key: Key(d.uuid!),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _showDeleteConfirmation(context, d),
              onDismissed: (_) {
                // Must remove immediately so Dismissible leaves the tree.
                controller.deleteDisease(d.uuid!);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.statusRed.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white, size: 26),
              ),
              child: DiseaseCard(
                name: d.name ?? '',
                status: d.status ?? '',
                diagnosed: d.diagnosedOn ?? '',
                doctor: d.category ?? 'Primary Care',
                type: d.conditionType,
                heroTag: heroTag,
                onTap: () {
                  Get.to(() => DiseaseDetailScreen(
                        diseaseName: d.name ?? '',
                        status: d.status ?? '',
                        uuid: d.uuid!,
                        heroTag: heroTag,
                      ));
                },
              ),
            );
          },
        ),
      );
    });
  }
}

Future<bool?> _showDeleteConfirmation(
  BuildContext context,
  DiseaseResult d,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      title: Text('Delete disease?',
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800)),
      content: Text(
        'Are you sure you want to delete ${d.name}? This cannot be undone.',
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.textGray)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete',
              style: TextStyle(color: AppColors.statusRed)),
        ),
      ],
    ),
  );
}

class _MedicationsTab extends StatelessWidget {
  final RecordsController controller;
  final Future<void> Function(Medication) onConfirmDelete;

  const _MedicationsTab({
    required this.controller,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCurrentMedicationsLoading.value &&
          controller.medications.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        );
      }
      if (controller.medications.isEmpty) {
        return const _EmptyState(
          icon: Icons.medication_outlined,
          title: 'No current medications',
          subtitle:
              'Medicines linked to your diseases will show up here.',
        );
      }
      return RefreshIndicator(
        color: AppColors.teal,
        onRefresh: () => controller.fetchCurrentMedications(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          itemCount: controller.medications.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Active medicines',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.medications.length} active',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            final m = controller.medications[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MedicationCard(
                medication: m,
                onTap: () {
                  if (m.id.isEmpty) return;
                  Get.to(() => MedicationDetailScreen(medicationUuid: m.id));
                },
                onDelete: () => onConfirmDelete(m),
              ),
            );
          },
        ),
      );
    });
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.medication,
    required this.onTap,
    required this.onDelete,
  });

  String _fmtTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h24 = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:$m $ampm';
  }

  Color _doseColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
      case 'completed':
        return AppColors.statusResolved;
      case 'missed':
        return AppColors.statusRed;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final reminderTimes = m.reminderTimes;
    final next = m.nextDoseTime;
    final doses = m.dosesToday;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealDark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2EE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: AppColors.tealDark, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.subtitle.isNotEmpty
                              ? m.subtitle
                              : '${m.frequencyDisplay} · ${m.timing}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (m.diseaseName.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              m.diseaseName,
                              style: const TextStyle(
                                color: AppColors.tealDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: AppColors.teal.withValues(alpha: 0.55)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: AppColors.statusRed)),
                      ),
                    ],
                  ),
                ],
              ),
              if (m.isReminderEnabled &&
                  (reminderTimes.isNotEmpty || doses.isNotEmpty)) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              size: 16, color: AppColors.tealDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              next != null && next.isNotEmpty
                                  ? 'Next dose · ${_fmtTime(next)}'
                                  : 'Reminder times',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: AppColors.tealDark,
                              ),
                            ),
                          ),
                          if (reminderTimes.isNotEmpty)
                            Text(
                              reminderTimes.map(_fmtTime).join(' · '),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      if (doses.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: doses.map((d) {
                            final color = _doseColor(d.status);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_fmtTime(d.time)} · ${d.status}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
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

class _TimelineTab extends StatelessWidget {
  final RecordsController controller;
  final IconData Function(String) eventIcon;
  final VoidCallback onEmptyAdd;

  const _TimelineTab({
    required this.controller,
    required this.eventIcon,
    required this.onEmptyAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // const Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 16),
          //   child: Text(
          //     'Timeline',
          //     style: TextStyle(
          //       fontSize: 18,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          const SizedBox(height: 11),
          // const Divider(height: 1),
          Expanded(
            child: controller.isLoading.value &&
                    controller.timelineEvents.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : controller.timelineEvents.isEmpty
                    ? _EmptyState(
                        icon: Icons.timeline_rounded,
                        title: 'Timeline is empty',
                        subtitle:
                            'Diseases, medicines and health events will appear here as a journey.',
                        cta: 'Add Record',
                        onTap: onEmptyAdd,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                        itemCount: controller.timelineEvents.length,
                        itemBuilder: (_, i) {
                          final e = controller.timelineEvents[i];
                          return TimelineEventRow(
                            title: e.title,
                            time: e.time,
                            icon: eventIcon(e.type),
                            iconColor: Color(int.parse(
                                e.colorCode.replaceAll('#', '0xFF'))),
                            isLast: i == controller.timelineEvents.length - 1,
                          );
                        },
                      ),
          ),
        ],
      );
    });
  }
}

// ── Shared chrome ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? cta;
  final VoidCallback? onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
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
              child: Icon(icon, size: 44, color: AppColors.tealDark),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGray,
                height: 1.45,
              ),
            ),
            if (cta != null && onTap != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                  child: Text(
                    cta!,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordsFab extends StatelessWidget {
  final VoidCallback onTap;
  const _RecordsFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tealDark,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: AppColors.tealDark.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _SheetAction {
  final String step;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetAction({
    required this.step,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _PremiumActionSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_SheetAction> options;

  const _PremiumActionSheet({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF2F6F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A5C45),
                    Color(0xFF147A68),
                    Color(0xFF1B9E8E)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
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
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w500,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(Icons.close_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + bottom),
              child: Column(
                children: [
                  for (int i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _PremiumSheetOption(action: options[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSheetOption extends StatelessWidget {
  final _SheetAction action;
  const _PremiumSheetOption({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealDark.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            action.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F7F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            action.step,
                            style: TextStyle(
                              color: action.color,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: action.color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
