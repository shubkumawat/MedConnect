import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../controllers/records_controller.dart';
import 'add_medication_screen.dart';
import 'add_disease_screen.dart';
import 'disease_detail_screen.dart';
import 'ai_prescription_screen.dart';

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
  }

  @override
  void dispose() {
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
          CustomIconButton(
            icon: Icons.add,
            onTap: () => _showAddDiseaseSheet(context),
            bgColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
          ),
          const SizedBox(width: 12),
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
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: controller.diseases.length,
                itemBuilder: (context, index) {
                  final d = controller.diseases[index];
                  final heroTag = 'disease_${d.id}';
                  return DiseaseCard(
                    name: d.name,
                    status: d.status,
                    diagnosed: d.diagnosedDate,
                    doctor: d.doctorName,
                    heroTag: heroTag,
                    onTap: () {
                      Get.to(DiseaseDetailScreen(
                        diseaseName: d.name,
                        status: d.status,
                        heroTag: heroTag,
                      ));
                    },
                  );
                },
              )),

          // ── Medications Tab ───────────────────────────────────
          Obx(() => controller.isLoading.value 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: controller.medications.length,
                itemBuilder: (context, index) {
                  final m = controller.medications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                            child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${m.frequency} · ${m.timing}', style: AppTextStyles.caption),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            ),
                          ),
                          CustomIconButton(
                            icon: Icons.alarm_rounded,
                            onTap: () {},
                            bgColor: AppColors.orange.withOpacity(0.1),
                            iconColor: AppColors.orange,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),

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
              Get.to(AddMedicationScreen());
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
