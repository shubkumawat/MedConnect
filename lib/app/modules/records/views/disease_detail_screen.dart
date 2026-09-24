import 'package:healora/app/data/models/appointment_model.dart';
import 'package:healora/app/modules/records/views/ai_prescription_screen.dart';
import 'add_appointment_screen.dart';
import 'appointment_detail_screen.dart';
import 'add_disease_screen.dart';
import 'add_disease_document_screen.dart';
import 'add_medication_screen.dart';
import 'document_viewer_screen.dart';
import 'medication_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healora/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/healora_logo.dart';
import '../controllers/records_controller.dart';
import 'package:healora/app/data/models/disease_document_model.dart';
import 'package:healora/app/data/models/medical_record_model.dart';
import 'package:intl/intl.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final String diseaseName;
  final String status;
  final String uuid;
  final String? heroTag;

  const DiseaseDetailScreen({
    super.key,
    required this.diseaseName,
    required this.status,
    required this.uuid,
    this.heroTag,
  });

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final RecordsController controller = Get.find<RecordsController>();

  Color get _statusColor {
    final status = controller.selectedDisease.value?.status?.toLowerCase() ??
        widget.status.toLowerCase();
    switch (status) {
      case 'active':
        return AppColors.statusActive;
      case 'monitoring':
      case 'under monitoring':
        return AppColors.statusMonitor;
      case 'resolved':
      case 'in remission':
        return AppColors.statusResolved;
      default:
        return AppColors.teal;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedDisease.value = null;
      controller.diseaseMedications.clear();
      controller.diseaseTimeline.clear();
      controller.diseaseDocuments.clear();
      controller.documentTypeFilter.value = 'prescription';
      controller.fetchDiseaseDetail(widget.uuid);
      controller.fetchDiseaseAppointments(widget.uuid);
    });
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    setState(() {});
    if (_tabCtrl.index == 1) {
      controller.fetchDiseaseMedications(widget.uuid);
    } else if (_tabCtrl.index == 2) {
      controller.fetchDiseaseDocuments(widget.uuid);
      controller.fetchReportTypesMeta();
    } else if (_tabCtrl.index == 3) {
      controller.fetchDiseaseTimeline(widget.uuid);
    }
  }

  Future<void> _openUploadDocument() async {
    final next = controller.selectedDisease.value?.nextAppointment;
    final result = await Get.to(() => AddDiseaseDocumentScreen(
          diseaseUuid: widget.uuid,
          initialDocType: controller.documentTypeFilter.value,
          appointmentUuid: next?.uuid,
        ));
    if (result == true) {
      await controller.fetchDiseaseDocuments(widget.uuid);
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          Obx(() {
            final d = controller.selectedDisease.value;
            return _DetailHeader(
              topPad: top,
              name: d?.name ?? widget.diseaseName,
              status: d?.status ?? widget.status,
              statusColor: _statusColor,
              conditionType: d?.conditionType,
              diagnosedOn: d?.diagnosedOn,
              tabIndex: _tabCtrl.index,
              onBack: () => Navigator.pop(context),
              onPdf: () => controller.exportDiseasePdf(widget.uuid),
              onEdit: () async {
                if (controller.selectedDisease.value == null) return;
                await Get.to(() => AddDiseaseScreen(
                      disease: controller.selectedDisease.value,
                    ));
                // Refresh detail + list after update without manual pull.
                await controller.fetchDiseaseDetail(widget.uuid);
                if (_tabCtrl.index == 1) {
                  await controller.fetchDiseaseMedications(widget.uuid);
                } else if (_tabCtrl.index == 2) {
                  await controller.fetchDiseaseDocuments(widget.uuid);
                }
              },
              onTabSelected: (i) {
                _tabCtrl.animateTo(i);
                setState(() {});
              },
            );
          }),
          Expanded(
            child: Obx(() => controller.isLoading.value &&
                    controller.selectedDisease.value == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _OverviewTab(
                        statusColor: _statusColor,
                        diseaseUuid: widget.uuid,
                        diseaseName: widget.diseaseName,
                      ),
                      _buildMedicationsTab(),
                      _buildDocumentsTab(),
                      _buildTimelineTab(),
                    ],
                  )),
          ),
        ],
      ),
      floatingActionButton: _tabCtrl.index == 0
          ? _Fab(
              icon: Icons.event_available_rounded,
              label: 'Appointment',
              onTap: () async {
                final ok = await Get.to(() => AddAppointmentScreen(
                      diseaseUuid: widget.uuid,
                      diseaseName: widget.diseaseName,
                    ));
                if (ok == true) {
                  await controller.fetchDiseaseAppointments(widget.uuid);
                }
              },
            )
          : _tabCtrl.index == 1
          ? _Fab(
              icon: Icons.add_rounded,
              onTap: () async {
                final next = controller.selectedDisease.value?.nextAppointment;
                await Get.to(() => AddMedicationScreen(
                      diseaseUuid: widget.uuid,
                      appointmentUuid: next?.uuid,
                    ));
                await controller.fetchDiseaseMedications(widget.uuid);
              },
            )
          : _tabCtrl.index == 2
              ? _Fab(
                  icon: Icons.upload_file_rounded,
                  label: 'Upload',
                  onTap: _openUploadDocument,
                )
              : null,
    );
  }

  Widget _buildMedicationsTab() {
    return Obx(() {
      if (controller.isMedicationsLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        );
      }
      if (controller.diseaseMedications.isEmpty) {
        return _TabEmpty(
          icon: Icons.medication_outlined,
          title: 'No medications linked',
          subtitle: 'Add medicines prescribed for this condition.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: controller.diseaseMedications.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
              child: Text(
                'Linked medications',
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            );
          }
          final med = controller.diseaseMedications[i - 1];
          final next = med.nextDoseTime;
          final times = med.reminderTimes;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: med.id.isEmpty
                    ? null
                    : () async {
                        await Get.to(() =>
                            MedicationDetailScreen(medicationUuid: med.id));
                        await controller.fetchDiseaseMedications(widget.uuid);
                      },
                child: _WhiteCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2EE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: AppColors.tealDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name.isNotEmpty
                                  ? med.name
                                  : 'NA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              med.subtitle.isNotEmpty
                                  ? med.subtitle
                                  : 'No details',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                            if (med.isReminderEnabled &&
                                (next != null || times.isNotEmpty)) ...[
                              const SizedBox(height: 6),
                              Text(
                                next != null && next.isNotEmpty
                                    ? 'Next dose · $next'
                                    : 'Reminders · ${times.join(' · ')}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.tealDark,
                                  fontWeight: FontWeight.w700,
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
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Get.to(() => AddMedicationScreen(
                                  diseaseUuid: widget.uuid,
                                  medication: med,
                                ));
                            await controller
                                .fetchDiseaseMedications(widget.uuid);
                          } else if (value == 'delete') {
                            _confirmDeleteMedication(med);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style:
                                    TextStyle(color: AppColors.statusRed)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Future<void> _confirmDeleteMedication(Medication med) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Medication'),
        content: Text('Remove "${med.name}" from this condition?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
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
        diseaseUuid: widget.uuid,
        isCurrentMedication: false,
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

  Widget _buildDocumentsTab() {
    return Obx(() {
      final filter = controller.documentTypeFilter.value;
      final docs = controller.diseaseDocuments;
      final loading = controller.isDocumentsLoading.value;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _DocTypeChip(
                    label: 'Prescription',
                    selected: filter == 'prescription',
                    onTap: () => controller.setDocumentTypeFilter(
                        widget.uuid, 'prescription'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DocTypeChip(
                    label: 'Report',
                    selected: filter == 'report',
                    onTap: () =>
                        controller.setDocumentTypeFilter(widget.uuid, 'report'),
                  ),
                ),
              ],
            ),
          ),
          if (filter == 'prescription')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  // Expanded(
                  //   child: _ActionBtn(
                  //     label: 'Scan with AI',
                  //     filled: false,
                  //     onTap: () => Get.to(
                  //         () => AiPrescriptionScreen(diseaseUuid: widget.uuid)),
                  //   ),
                  //   ),
                  // ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Upload',
                      filled: true,
                      onTap: _openUploadDocument,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ActionBtn(
                label: 'Upload Report',
                filled: true,
                onTap: _openUploadDocument,
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : docs.isEmpty
                    ? _TabEmpty(
                        icon: filter == 'prescription'
                            ? Icons.document_scanner_outlined
                            : Icons.biotech_outlined,
                        title: filter == 'prescription'
                            ? 'No prescriptions yet'
                            : 'No reports yet',
                        subtitle: filter == 'prescription'
                            ? 'Upload RX slips or scan with AI.'
                            : 'Upload blood, urine and other lab reports.',
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: docs.length,
                        itemBuilder: (_, i) =>
                            _DiseaseDocumentCard(document: docs[i]),
                      ),
          ),
        ],
      );
    });
  }

  Widget _buildTimelineTab() {
    return Obx(() {
      if (controller.isTimelineLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        );
      }
      if (controller.diseaseTimeline.isEmpty) {
        return const _TabEmpty(
          icon: Icons.timeline_rounded,
          title: 'No timeline events',
          subtitle: 'Activity for this disease will appear here automatically.',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: controller.diseaseTimeline.length,
        itemBuilder: (_, i) {
          final e = controller.diseaseTimeline[i];
          return TimelineEventRow(
            title: e.title,
            time: e.time,
            icon: _eventIcon(e.type),
            iconColor: _eventColor(e.colorCode),
            isLast: i == controller.diseaseTimeline.length - 1,
          );
        },
      );
    });
  }

  Color _eventColor(String colorCode) {
    try {
      final hex = colorCode.replaceAll('#', '').trim();
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return AppColors.teal;
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'medication_added':
      case 'med':
        return Icons.medication_rounded;
      case 'document_added':
      case 'doc':
        return Icons.description_rounded;
      case 'disease_created':
      case 'disease_updated':
        return Icons.medical_information_rounded;
      case 'qr':
        return Icons.qr_code_rounded;
      case 'hosp':
        return Icons.local_hospital_rounded;
      case 'vac':
        return Icons.vaccines_rounded;
      default:
        return Icons.timeline_rounded;
    }
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final double topPad;
  final String name;
  final String status;
  final Color statusColor;
  final String? conditionType;
  final String? diagnosedOn;
  final int tabIndex;
  final VoidCallback onBack;
  final VoidCallback onPdf;
  final VoidCallback onEdit;
  final ValueChanged<int> onTabSelected;

  const _DetailHeader({
    required this.topPad,
    required this.name,
    required this.status,
    required this.statusColor,
    required this.conditionType,
    required this.diagnosedOn,
    required this.tabIndex,
    required this.onBack,
    required this.onPdf,
    required this.onEdit,
    required this.onTabSelected,
  });

  String get _diagnosedLabel {
    if (diagnosedOn == null || diagnosedOn!.isEmpty) return 'Diagnosis date —';
    try {
      return 'Diagnosed ${DateFormat('MMM yyyy').format(DateTime.parse(diagnosedOn!))}';
    } catch (_) {
      return 'Diagnosed $diagnosedOn';
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Overview', 'Medications', 'Documents', 'Timeline'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
              ),
              const SizedBox(width: 10),
              const HealoraLogo.chip(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disease Detail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _IconBtn(icon: Icons.picture_as_pdf_outlined, onTap: onPdf),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.edit_outlined, onTap: onEdit),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (conditionType != null && conditionType!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    conditionType!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                _diagnosedLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = tabIndex == i;
                return Padding(
                  padding: EdgeInsets.only(right: i == tabs.length - 1 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => onTabSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          color: selected
                              ? AppColors.tealDark
                              : Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

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
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Color statusColor;
  final String diseaseUuid;
  final String diseaseName;
  const _OverviewTab({
    required this.statusColor,
    required this.diseaseUuid,
    required this.diseaseName,
  });

  Future<void> _openAdd(RecordsController controller) async {
    final ok = await Get.to(() => AddAppointmentScreen(
          diseaseUuid: diseaseUuid,
          diseaseName: diseaseName,
        ));
    if (ok == true) {
      await controller.fetchDiseaseAppointments(diseaseUuid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecordsController>();
    final d = controller.selectedDisease.value;
    if (d == null) return const SizedBox.shrink();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Obx(() {
          final loading = controller.isAppointmentsLoading.value;
          final items = controller.diseaseAppointments.toList();
          final next = d.nextAppointment ??
              items.where((a) => a.isScheduled).firstOrNull;
          return _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Appointments',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAdd(controller),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.tealDark,
                      ),
                    ),
                  ],
                ),
                if (loading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  )
                else if (items.isEmpty && next == null)
                  Text(
                    'No visits scheduled. Add a follow-up so Healora can remind you a day before.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textGray,
                      height: 1.4,
                      fontSize: 13.5,
                    ),
                  )
                else ...[
                  if (next != null && next.uuid.isNotEmpty) ...[
                    Text(
                      'Next visit',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AppointmentTile(
                      appointment: next,
                      onTap: () async {
                        await Get.to(() => AppointmentDetailScreen(
                              appointmentUuid: next.uuid,
                              diseaseUuid: diseaseUuid,
                              diseaseName: diseaseName,
                            ));
                        await controller.fetchDiseaseAppointments(diseaseUuid);
                      },
                    ),
                    if (items.where((a) => a.uuid != next.uuid).isNotEmpty)
                      const SizedBox(height: 12),
                  ],
                  ...items
                      .where((a) => a.uuid != next?.uuid)
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _AppointmentTile(
                            appointment: a,
                            onTap: () async {
                              await Get.to(() => AppointmentDetailScreen(
                                    appointmentUuid: a.uuid,
                                    diseaseUuid: diseaseUuid,
                                    diseaseName: diseaseName,
                                  ));
                              await controller
                                  .fetchDiseaseAppointments(diseaseUuid);
                            },
                          ),
                        ),
                      ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _WhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Clinical summary',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (d.status ?? 'Active').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoGrid(
                items: [
                  _InfoItem('Condition type',
                      d.conditionType?.capitalizeFirst ?? '—'),
                  _InfoItem(
                      'Severity', d.severity?.capitalizeFirst ?? '—'),
                  _InfoItem('Diagnosed on', _formatDate(d.diagnosedOn)),
                  _InfoItem(
                      'Recovered on',
                      d.recoveredOn != null
                          ? _formatDate(d.recoveredOn)
                          : '—'),
                  _InfoItem(
                      'Affected area',
                      (d.bodyParts ?? []).isEmpty
                          ? '—'
                          : (d.bodyParts ?? []).join(', ').capitalizeFirst ??
                              '—'),
                  _InfoItem(
                      'Hereditary', d.hereditary?.capitalizeFirst ?? '—'),
                  _InfoItem('Category', d.category ?? '—'),
                  _InfoItem(
                      'Follow-up',
                      d.nextFollowUpOn != null &&
                              d.nextFollowUpOn!.isNotEmpty
                          ? _formatDate(d.nextFollowUpOn)
                          : '—'),
                ],
              ),
            ],
          ),
        ),
        if (d.hospitalizationRequired == true) ...[
          const SizedBox(height: 12),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.local_hotel_outlined,
                          color: AppColors.orange, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Hospitalization',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoGrid(
                  items: [
                    _InfoItem('Admitted', _formatDate(d.admittedOn)),
                    _InfoItem('Discharged', _formatDate(d.dischargedOn)),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _WhiteCard(
          color: AppColors.teal.withValues(alpha: 0.05),
          borderColor: AppColors.teal.withValues(alpha: 0.18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.tealDark, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AI medical insights',
                    style: AppTextStyles.bodyBold
                        .copyWith(color: AppColors.tealDark),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                d.aiInsights ??
                    'Upload prescriptions or bills to unlock AI insights for this condition.',
                style: AppTextStyles.body.copyWith(
                  fontStyle:
                      d.aiInsights == null ? FontStyle.italic : FontStyle.normal,
                  fontSize: 13.5,
                  height: 1.45,
                  color: d.aiInsights == null
                      ? AppColors.textGray
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        if (d.notes != null && d.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes & observations',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d.notes!,
                  style: AppTextStyles.body.copyWith(
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (d.icdCode != null && d.icdCode!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _WhiteCard(
            child: _InfoRow('ICD code', d.icdCode!),
          ),
        ],
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 10 : 0),
            child: Row(
              children: [
                Expanded(child: _InfoCell(items[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < items.length
                      ? _InfoCell(items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  final _InfoItem item;
  const _InfoCell(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textGray)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Documents ────────────────────────────────────────────────────────────────

class _DocTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DocTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.tealDark : const Color(0xFFE3EBE7),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

class _DiseaseDocumentCard extends StatelessWidget {
  final DiseaseDocument document;
  const _DiseaseDocumentCard({required this.document});

  String _dateLabel() {
    final raw = document.documentDate ?? document.createdAt;
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = document.coverUrl;
    final isRx = document.isPrescription;
    final pages = document.pageCount > 0
        ? document.pageCount
        : document.files.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _WhiteCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFFE8F2EE),
                child: cover != null && cover.isNotEmpty
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          isRx
                              ? Icons.description_outlined
                              : Icons.biotech_outlined,
                          color: AppColors.tealDark,
                        ),
                      )
                    : Icon(
                        isRx
                            ? Icons.description_outlined
                            : Icons.biotech_outlined,
                        color: AppColors.tealDark,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (document.reportType?.name != null)
                        document.reportType!.name!,
                      if (pages > 0) '$pages page${pages == 1 ? '' : 's'}',
                      _dateLabel(),
                    ].where((e) => e.isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textGray),
                  ),
                  if (document.summary != null &&
                      document.summary!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      document.summary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFFE8F2EE),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => Get.to(
                    () => DocumentViewerScreen(document: document)),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
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

// ── Shared chrome ────────────────────────────────────────────────────────────

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;

  const _WhiteCard({
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? const Color(0xFFE3EBE7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TabEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  const _TabEmpty({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 36,
          vertical: compact ? 28 : 0,
        ),
        child: Column(
          mainAxisAlignment:
              compact ? MainAxisAlignment.start : MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 72 : 88,
              height: compact ? 72 : 88,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: compact ? 32 : 40, color: AppColors.tealDark),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textGray,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tealDark,
                side: BorderSide(
                    color: AppColors.teal.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final DiseaseAppointment appointment;
  final VoidCallback onTap;

  const _AppointmentTile({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cancelled = appointment.isCancelled;
    return Material(
      color: const Color(0xFFF7FBFA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                cancelled
                    ? Icons.event_busy_rounded
                    : Icons.event_available_rounded,
                color: cancelled ? AppColors.statusRed : AppColors.tealDark,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.whenLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.kindLabel} · ${appointment.statusLabel}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
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

class _Fab extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _Fab({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: AppColors.tealDark,
        icon: Icon(icon, color: Colors.white),
        label: Text(label!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
      );
    }
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AppColors.tealDark,
      child: Icon(icon, color: Colors.white),
    );
  }
}
