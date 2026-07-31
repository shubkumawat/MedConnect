import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_timeline_event_screen.dart';
import 'package:digitalhealth/app/modules/records/views/ai_prescription_screen.dart';
import 'add_disease_screen.dart';
import 'add_medication_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../controllers/records_controller.dart';
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
    final status = controller.selectedDisease.value?.status?.toLowerCase() ?? widget.status.toLowerCase();
    switch (status) {
      case 'active':    return AppColors.statusActive;
      case 'monitoring':return AppColors.statusMonitor;
      case 'resolved':  return AppColors.statusResolved;
      default:          return AppColors.textMuted;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selectedDisease.value = null;
      controller.diseaseMedications.clear();
      controller.diseaseTimeline.clear();
      controller.fetchDiseaseDetail(widget.uuid);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Obx(() {
          final d = controller.selectedDisease.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d?.name ?? widget.diseaseName,
                style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (d?.status ?? widget.status).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            onPressed: () {
              controller.exportDiseasePdf(widget.uuid);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            onPressed: () {
              if (controller.selectedDisease.value != null) {
                Get.to(() => AddDiseaseScreen(disease: controller.selectedDisease.value));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: AppTextStyles.captionBold,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Medications'),
            Tab(text: 'Slips & RX'),
            Tab(text: 'Bills'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: Obx(() => controller.isLoading.value 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabCtrl,
            children: [
              // Overview
              _OverviewTab(statusColor: _statusColor),

              // Medications
              _buildMedicationsTab(),

              // Slips
              _buildSlipsTab(),

              // Receipts
              _buildReceiptsTab(),

              // Timeline
              _buildTimelineTab(),
            ],
          ),
      ),
      floatingActionButton: _tabCtrl.index == 4 ? FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => AddTimelineEventScreen(diseaseUuid: widget.uuid));
        },
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Add to Timeline', style: TextStyle(color: Colors.white)),
      ) : null,
    );
  }

  Widget _buildMockVisits() {
    final visits = [
      {'date': 'Jan 2023', 'doctor': 'Dr. Sharma', 'hospital': 'Fortis Hospital', 'notes': 'Initial diagnosis, MRI ordered'},
      {'date': 'Apr 2023', 'doctor': 'Dr. Gupta', 'hospital': 'Apollo Clinic', 'notes': 'Follow-up, conservative treatment'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: visits.length,
      itemBuilder: (_, i) {
        final v = visits[i];
        return McCard(
          isPremium: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(v['date']!, style: AppTextStyles.captionBold.copyWith(color: AppColors.accentBlue)),
                  ),
                  const Spacer(),
                  Text(v['hospital']!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.person_pin_rounded, color: AppColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(v['doctor']!, style: AppTextStyles.bodyBold),
                ],
              ),
              const SizedBox(height: 8),
              Text(v['notes']!, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              CustomOutlineButton(text: 'View Details', onTap: () {}, height: 36),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    return Obx(() => ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: Text('Medications linked to this condition', style: AppTextStyles.caption)),
        const SizedBox(height: 16),
        if (controller.diseaseMedications.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.medication_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text("No medications found", style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          )
        else
          ...controller.diseaseMedications.map((med) => McCard(
            isPremium: true,
            padding: const EdgeInsets.all(16),
            // margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name ?? 'Unknown Medication', style: AppTextStyles.bodyBold),
                      const SizedBox(height: 2),
                      Text('${med.frequency ?? ''} · ${med.timing ?? ''}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          )),
        const SizedBox(height: 12),
        CustomOutlineButton(text: '+ Add Medication', onTap: () => Get.to(() => const AddMedicationScreen())),
      ],
    ));
  }

  Widget _buildSlipsTab() {
    return Obx(() {
      if (controller.isDocumentsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (controller.diseaseDocuments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 64),
                  const SizedBox(height: 20),
                  Text('No prescription slips yet', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ...controller.diseaseDocuments.map((doc) => _buildDocumentCard(doc)),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomPrimaryButton(
                  text: 'Scan with AI',
                  color: AppColors.teal,
                  onTap: () => Get.to(() => AiPrescriptionScreen(diseaseUuid: widget.uuid)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomOutlineButton(
                  text: 'Upload Slip',
                  onTap: () => _pickAndUpload('slip'),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildReceiptsTab() {
    return Obx(() {
      if (controller.isBillsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (controller.diseaseBills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 64),
                  const SizedBox(height: 20),
                  Text('No receipts uploaded', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ...controller.diseaseBills.map((doc) => _buildDocumentCard(doc)),

          const SizedBox(height: 24),
          CustomPrimaryButton(
            text: 'Upload Receipt',
            color: AppColors.primary,
            onTap: () => _pickAndUpload('bill'),
          ),
        ],
      );
    });
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return McCard(
      isPremium: true,
      // margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.bgDeepNavy,
              borderRadius: BorderRadius.circular(8),
              image: doc['file'] != null ? DecorationImage(
                image: NetworkImage(doc['file']),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: doc['file'] == null ? const Icon(Icons.description, color: AppColors.teal) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['name'] ?? 'Medical Document', style: AppTextStyles.bodyBold),
                Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(doc['created_at'] ?? DateTime.now().toString())), style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: AppColors.primary, size: 20),
            onPressed: () {
              if (doc['file'] != null) {
                launchUrl(Uri.parse(doc['file']), mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      bool success = await controller.uploadDiseaseDocument(widget.uuid, image.path, type);
      if (success) {
        Get.snackbar("Success", "Document uploaded successfully", 
          backgroundColor: AppColors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Failed to upload document", 
          backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Widget _buildTimelineTab() {
    return Obx(() => controller.isTimelineLoading.value 
      ? const Center(child: CircularProgressIndicator())
      : controller.diseaseTimeline.isEmpty
        ? Center(child: Text("No events in timeline", style: AppTextStyles.body))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.diseaseTimeline.length,
            itemBuilder: (_, i) {
              final e = controller.diseaseTimeline[i];
              return TimelineEventRow(
                title: e.title,
                time: e.time,
                icon: _eventIcon(e.type),
                iconColor: Color(int.parse(e.colorCode.replaceAll('#', '0xFF'))),
                isLast: i == controller.diseaseTimeline.length - 1,
              );
            },
          ),
    );
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
}

class _OverviewTab extends StatelessWidget {
  final Color statusColor;
  const _OverviewTab({required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecordsController>();
    final d = controller.selectedDisease.value;

    if (d == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        McCard(
          isPremium: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Summary', style: AppTextStyles.heading3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      (d.status ?? 'Active').toUpperCase(),
                      style: AppTextStyles.captionBold.copyWith(color: statusColor, fontSize: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow('Doctor', d.category ?? 'Primary Care'),
              _InfoRow('Hospital', 'City Medical Center'), // Mocked
              _InfoRow('Condition Type', d.conditionType?.capitalizeFirst ?? 'Chronic'),
              _InfoRow('Severity', d.severity?.capitalizeFirst ?? 'Moderate'),
              _InfoRow('Diagnosed On', _formatDate(d.diagnosedOn)),
              if (d.recoveredOn != null) _InfoRow('Recovered On', _formatDate(d.recoveredOn)),
              _InfoRow('Affected Area', (d.bodyParts ?? []).join(', ').capitalizeFirst ?? 'General'),
              _InfoRow('Hereditary', d.hereditary?.capitalizeFirst ?? 'No'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // AI Extraction Summary Placeholder
        McCard(
          isPremium: true,
          color: AppColors.primary.withOpacity(0.05),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('AI Medical Insights', style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                d.aiInsights ?? 'Upload prescriptions or bills to get AI-powered insights and health recommendations for this condition.',
                style: AppTextStyles.body.copyWith(
                  fontStyle: d.aiInsights == null ? FontStyle.italic : FontStyle.normal,
                  fontSize: 13,
                  color: d.aiInsights == null ? AppColors.textGray : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        if (d.notes != null && d.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          McCard(
            isPremium: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notes & Observations', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(d.notes!, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }
}



class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.bodyBold)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.bgDeepNavy, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_) => false;
}
