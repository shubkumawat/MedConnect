import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/records_controller.dart';

class MedicationDetailScreen extends StatelessWidget {
  final String medicationUuid;

  const MedicationDetailScreen({super.key, required this.medicationUuid});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecordsController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Medication Details', showBack: true),
      body: FutureBuilder<Medication?>(
        future: controller.fetchMedicationDetail(medicationUuid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              controller.isMedicationDetailLoading.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.teal));
          }

          final med = snapshot.data ?? controller.selectedMedication.value;
          if (med == null) {
            return Center(
              child: Text(
                'Unable to load medication details.',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                McCard(
                  isPremium: true,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: AppColors.teal, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name.isNotEmpty ? med.name : 'Medication',
                              style: AppTextStyles.heading3.copyWith(color: AppColors.tealDark),
                            ),
                            if (med.strength != null && med.strength!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(med.strength!, style: AppTextStyles.caption),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                McCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Dosage', med.dosage),
                      _row('Frequency', med.frequencyDisplay),
                      _row('Timing', med.timing.isNotEmpty ? med.timing : null),
                      _row(
                        'With Food',
                        med.withFood?.replaceAll('_', ' '),
                      ),
                      _row('Start Date', med.startDate),
                      _row(
                        'End Date',
                        med.isOngoing
                            ? 'Ongoing'
                            : (med.endDate?.isNotEmpty == true ? med.endDate : null),
                      ),
                      _row('Prescribed By', med.prescribedBy),
                      _row('Linked Disease', med.diseaseName.isNotEmpty ? med.diseaseName : null),
                      _row('Instructions', med.instructions),
                      _row('Status', med.isActive ? 'Active' : 'Inactive'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String? value) {
    final display = (value != null && value.trim().isNotEmpty) ? value : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              display,
              style: AppTextStyles.body.copyWith(color: AppColors.textTail, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
