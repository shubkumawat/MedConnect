import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/healora_logo.dart';
import '../../../data/models/appointment_model.dart';
import '../controllers/records_controller.dart';
import 'add_disease_document_screen.dart';
import 'add_medication_screen.dart';
import 'appointment_recording_card.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentUuid;
  final String diseaseUuid;
  final String diseaseName;

  const AppointmentDetailScreen({
    super.key,
    required this.appointmentUuid,
    required this.diseaseUuid,
    required this.diseaseName,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final RecordsController controller = Get.find<RecordsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchAppointmentDetail(widget.appointmentUuid);
    });
  }

  String _when(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('EEE, d MMM yyyy · hh:mm a')
          .format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _itemName(Map<String, dynamic> item) {
    return (item['name'] ??
            item['title'] ??
            item['medicine_name'] ??
            item['doctor_name'] ??
            item['hospital_name'] ??
            item['display_id'] ??
            'Item')
        .toString();
  }

  String _itemSub(Map<String, dynamic> item) {
    final parts = <String>[
      if ((item['severity'] ?? '').toString().isNotEmpty)
        item['severity'].toString(),
      if ((item['dosage_form'] ?? '').toString().isNotEmpty)
        item['dosage_form'].toString(),
      if ((item['notes'] ?? '').toString().isNotEmpty) item['notes'].toString(),
    ];
    return parts.join(' · ');
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel appointment?'),
        content: const Text(
            'The day-before reminder will also be cancelled. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel visit',
                style: TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.cancelAppointment(
        appointmentUuid: widget.appointmentUuid,
        diseaseUuid: widget.diseaseUuid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const HealoraLogo.chip(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visit details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        widget.diseaseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isAppointmentDetailLoading.value &&
                  controller.selectedAppointment.value == null) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.teal));
              }
              final a = controller.selectedAppointment.value;
              if (a == null) {
                return const Center(child: Text('Appointment not found.'));
              }
              return RefreshIndicator(
                color: AppColors.teal,
                onRefresh: () async {
                  await controller.fetchAppointmentDetail(widget.appointmentUuid);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.kindLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              _chip(
                                a.statusLabel,
                                a.isCancelled
                                    ? AppColors.statusRed
                                    : AppColors.tealDark,
                              ),
                            ],
                          ),
                          if (a.displayId != null) ...[
                            const SizedBox(height: 4),
                            Text(a.displayId!,
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.textGray)),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            _when(a.scheduledAt),
                            style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                          ),
                          if (a.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(a.notes,
                                style: AppTextStyles.body
                                    .copyWith(color: AppColors.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    if (a.isScheduled) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _action(
                              Icons.medication_rounded,
                              'Add medicine',
                              () async {
                                await Get.to(() => AddMedicationScreen(
                                      diseaseUuid: widget.diseaseUuid,
                                      appointmentUuid: widget.appointmentUuid,
                                    ));
                                await controller.fetchAppointmentDetail(
                                    widget.appointmentUuid);
                                await controller
                                    .fetchDiseaseMedications(widget.diseaseUuid);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _action(
                              Icons.upload_file_rounded,
                              'Add document',
                              () async {
                                await Get.to(() => AddDiseaseDocumentScreen(
                                      diseaseUuid: widget.diseaseUuid,
                                      appointmentUuid: widget.appointmentUuid,
                                    ));
                                await controller.fetchAppointmentDetail(
                                    widget.appointmentUuid);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusRed,
                          side: const BorderSide(color: AppColors.statusRed),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel appointment',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                    _section('Symptoms', a.symptoms),
                    _section('Medications', a.medications),
                    _section('Doctors', a.doctors),
                    _section('Hospitals', a.hospitals),
                    _section('Documents', a.documents),
                    _section('Receipts', a.receipts),
                    _section('Attachments', a.attachments),
                    _section('Prescriptions', a.prescriptions),
                    AppointmentRecordingCard(
                      appointmentUuid: widget.appointmentUuid,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text('None linked to this visit.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGray))
            else
              ...items.map((e) {
                final sub = _itemSub(e);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 7, color: AppColors.tealDark),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_itemName(e),
                                style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5)),
                            if (sub.isNotEmpty)
                              Text(sub,
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textGray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.tealDark),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: child,
    );
  }
}
