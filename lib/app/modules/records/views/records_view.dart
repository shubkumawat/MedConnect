import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../../../data/models/disease_response_model.dart';
import '../../../data/models/medical_record_model.dart';
import '../controllers/records_controller.dart';
import 'add_medication_screen.dart';
import 'add_disease_screen.dart' hide SizedBox;
import 'disease_detail_screen.dart';
import 'ai_prescription_screen.dart';
import 'medication_detail_screen.dart';
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
    controller.fetchDiseases();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    // Medications tab (index 1) — current medications only
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

  IconData _eventIcon(String type) {
    switch (type) {
      case 'med': return Icons.medication;
      case 'qr': return Icons.qr_code;
      case 'doc': return Icons.description;
      case 'hosp': return Icons.local_hospital;
      case 'vac': return Icons.vaccines;
      default: return Icons.circle;
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: CustomPrimaryButton(
                text: "Add Now",
                onTap: onTap,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.tealDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Ravi\'s Records',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
            onPressed: () {
              String name = "Patient";
              String? photo;
              String? patientId;
              if (Get.isRegistered<HomeController>()) {
                final home = Get.find<HomeController>();
                if (home.patients.isNotEmpty) {
                  final i = home.activePatientIndex.value.clamp(0, home.patients.length - 1);
                  final p = home.patients[i];
                  name = p.fullName ?? name;
                  photo = p.profilePhoto;
                  patientId = p.patientId;
                }
              }
              Get.to(() => QrScreen(
                    patientName: name,
                    patientId: patientId,
                    profilePhoto: photo,
                  ));
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: AppTextStyles.captionBold,
          tabs: const [
            Tab(text: 'Diseases'),
            Tab(text: 'Medications'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Diseases Tab ──────────────────────────────────────
          Obx(() => controller.isLoading.value 
            ? const Center(child: CircularProgressIndicator())
            : controller.diseases.isEmpty 
              ? _buildEmptyState(
                  icon: Icons.sick_outlined,
                  title: "No Diseases Added Yet",
                  subtitle: "Add your health conditions to keep track of your medical history.",
                  onTap: () => Get.to(AddDiseaseScreen()),
                )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: controller.diseases.length,
                itemBuilder: (context, index) {
                  final d = controller.diseases[index];
                  final heroTag = 'disease_${d.uuid}';
                  return Dismissible(
                    key: Key(d.uuid!),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        return await _showDeleteConfirmation(context, d);
                      }
                      return false;
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.statusActive,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                    ),
                    child: DiseaseCard(
                      name: d.name ?? '',
                      status: d.status ?? '',
                      diagnosed: d.diagnosedOn ?? '',
                      doctor: d.category ?? 'Primary Care',
                      type: d.conditionType,
                      heroTag: heroTag,
                      onTap: () {
                        Get.to(DiseaseDetailScreen(
                          diseaseName: d.name ?? '',
                          status: d.status ?? '',
                          uuid: d.uuid!,
                          heroTag: heroTag,
                        ));
                      },
                    ),
                  );
                },
              )),

          // ── Medications Tab (Current Medications only) ─────────
          Obx(() {
            if (controller.isCurrentMedicationsLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.medications.isEmpty) {
              return _buildEmptyState(
                icon: Icons.medication_outlined,
                title: "No Current Medications",
                subtitle: "Add your current medications to get timely reminders.",
                onTap: () async {
                  // await Get.to(() => const AddMedicationScreen(isCurrentMedication: true));
                },
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: controller.medications.length,
              itemBuilder: (context, index) {
                final m = controller.medications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      if (m.id.isEmpty) return;
                      Get.to(() => MedicationDetailScreen(medicationUuid: m.id));
                    },
                    child: McCard(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.medication_rounded,
                                color: AppColors.teal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  m.subtitle.isNotEmpty
                                      ? m.subtitle
                                      : '${m.frequencyDisplay} · ${m.timing}',
                                  style: AppTextStyles.caption,
                                ),
                                if (m.diseaseName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.diseaseName,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.teal,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textTail),
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _confirmDeleteCurrentMedication(m);
                              }
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
                    ),
                  ),
                );
              },
            );
          }),

          // ── Timeline Tab ──────────────────────────────────────
          Obx(() => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Diseases', 'Meds', 'Vaccines', 'QR']
                        .asMap()
                        .entries
                        .map((e) {
                      return McFilterChip(
                        label: e.value,
                        isSelected: controller.timelineFilter.value == e.key,
                        onTap: () => controller.updateTimelineFilter(e.key),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: controller.isLoading.value 
                  ? const Center(child: CircularProgressIndicator())
                  : controller.timelineEvents.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.timeline,
                        title: "Timeline Empty",
                        subtitle: "Your health journey events will appear here.",
                        onTap: () => _showAddDiseaseSheet(context),
                      )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: controller.timelineEvents.length,
                      itemBuilder: (_, i) {
                        final e = controller.timelineEvents[i];
                        return TimelineEventRow(
                          title: e.title,
                          time: e.time,
                          icon: _eventIcon(e.type),
                          iconColor: Color(int.parse(e.colorCode.replaceAll('#', '0xFF'))),
                          isLast: i == controller.timelineEvents.length - 1,
                        );
                      },
                    ),
              ),
            ],
          )),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: CustomFab(onTap: () => _showAddDiseaseSheet(context)),
      ),
    );
  }

  Future<void> _confirmDeleteCurrentMedication(Medication med) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Remove "${med.name}" from current medications?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        backgroundColor: ok ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, DiseaseResult d) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCardNavy,
        title: Text('Delete Disease?', style: AppTextStyles.heading3),
        content: Text('Are you sure you want to delete ${d.name}? This action cannot be undone.', 
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteDisease(d.uuid!);
              Navigator.pop(context, true);
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.statusActive)),
          ),
        ],
      ),
    );
  }

  void _showAddDiseaseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCardNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            _SheetOption(icon: Icons.sick, label: 'Add Disease', color: AppColors.statusActive, onTap: () { 
              Navigator.pop(context);
              Get.to(AddDiseaseScreen());
            }),
            const SizedBox(height: 10),
            _SheetOption(icon: Icons.medication, label: 'Add Medication', color: AppColors.teal, onTap: () { 
              Navigator.pop(context);
              Get.to(() => const AddMedicationScreen(isCurrentMedication: true));
            }),
            const SizedBox(height: 10),
            _SheetOption(icon: Icons.camera_alt, label: 'Scan Prescription (AI)', color: AppColors.primary, onTap: () { 
              Navigator.pop(context);
              Get.to(AiPrescriptionScreen());
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SheetOption({required this.icon, required this.label, required this.color, required this.onTap});
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: CustomPrimaryButton(
                text: "Add Now",
                onTap: onTap,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.bodyBold),
          ],
        ),
      ),
    );
  }
}
