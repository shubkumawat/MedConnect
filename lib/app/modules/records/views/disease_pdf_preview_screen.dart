import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:digitalhealth/app/data/models/disease_response_model.dart';
import 'package:digitalhealth/app/data/models/medical_record_model.dart';
import 'package:digitalhealth/app/modules/profile/controllers/profile_controller.dart';
import 'package:digitalhealth/app/core/theme/app_colors.dart';
import 'package:digitalhealth/app/core/theme/app_text_theme.dart';

class DiseasePdfPreviewScreen extends StatefulWidget {
  final DiseaseResult disease;
  final List<Medication> medications;
  final List<TimelineEvent> timeline;

  const DiseasePdfPreviewScreen({
    Key? key,
    required this.disease,
    required this.medications,
    required this.timeline,
  }) : super(key: key);

  @override
  State<DiseasePdfPreviewScreen> createState() => _DiseasePdfPreviewScreenState();
}

class _DiseasePdfPreviewScreenState extends State<DiseasePdfPreviewScreen> {
  late ProfileController profileCtrl;
  bool _isPrinting = false;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw "Capture failed";

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await Printing.layoutPdf(
        name: 'Medical_Report_${widget.disease.displayId}',
        onLayout: (format) async {
          final pdf = pw.Document();
          final pdfImage = pw.MemoryImage(pngBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(10),
              build: (_) => pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      Get.snackbar("Print Error", "Failed to generate print: $e",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.black, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.disease;
    // Patient name from profile or fallback
    final patientName = profileCtrl.fullNameCtrl.text.isEmpty ? "Dikshant Kumawat" : profileCtrl.fullNameCtrl.text;

    return Scaffold(
      backgroundColor: AppColors.bgDeepNavy,
      appBar: AppBar(
        title: Text("REPORT PREVIEW", style: AppTextStyles.appBar),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _receiptKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screenshot-style Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text("MedConnect — Health", 
                                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text("Generated for $patientName · Report ID ${d.displayId ?? "--"}", 
                                style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            const Divider(thickness: 2, color: AppColors.teal),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. PATIENT INFORMATION
                            _sectionHeader("Patient Information"),
                            const SizedBox(height: 15),
                            _detailRow("Name", patientName, isBold: true),
                            _detailRow("Patient ID", "PATIENT${profileCtrl.mobileNumber.value.isNotEmpty ? profileCtrl.mobileNumber.value.substring(profileCtrl.mobileNumber.value.length - (profileCtrl.mobileNumber.value.length > 6 ? 6 : profileCtrl.mobileNumber.value.length)) : "000004"}"),
                            _detailRow("Gender", profileCtrl.selectedGender.value.isEmpty ? "Male" : profileCtrl.selectedGender.value),
                            _detailRow("Date of Birth", profileCtrl.dobCtrl.text.isEmpty ? "15 Jun 2002" : profileCtrl.dobCtrl.text),
                            _detailRow("Blood Group", profileCtrl.bloodGroup.value.isEmpty ? "A+" : profileCtrl.bloodGroup.value),

                            const SizedBox(height: 25),
                            
                            // 2. DISEASE INFORMATION
                            _sectionHeader("Disease Condition"),
                            const SizedBox(height: 10),
                            _detailRow("Disease Name", d.name ?? "--", isBold: true),
                            _detailRow("Current Status", (d.status ?? "--").toUpperCase(), valueColor: (d.status?.toLowerCase() == 'active' ? AppColors.statusActive : AppColors.textDark)),
                            _detailRow("ICD Code", d.icdCode ?? "--"),
                            
                            const SizedBox(height: 20),
                            _sectionHeader("Clinical Overview"),
                            const SizedBox(height: 10),
                            _detailRow("Condition Type", d.conditionType ?? "--"),
                            _detailRow("Severity", d.severity ?? "--"),
                            _detailRow("Category", d.category ?? "General Medicine"),
                            _detailRow("Affected Parts", d.bodyParts != null && d.bodyParts!.isNotEmpty ? d.bodyParts!.join(", ") : "--"),

                            const SizedBox(height: 20),
                            _sectionHeader("Timeline Details"),
                            const SizedBox(height: 10),
                            _detailRow("Diagnosed On", d.diagnosedOn ?? "--"),
                            _detailRow("Recovered On", d.recoveredOn ?? "--"),
                            _detailRow("Next Follow-up", d.nextFollowUpOn ?? "--"),

                            if (d.hospitalizationRequired == true) ...[
                              const SizedBox(height: 20),
                              _sectionHeader("Hospitalization"),
                              const SizedBox(height: 10),
                              _detailRow("Admitted On", d.admittedOn ?? "--"),
                              _detailRow("Discharged On", d.dischargedOn ?? "--"),
                            ],

                            const SizedBox(height: 20),
                            _sectionHeader("Medications"),
                            const SizedBox(height: 10),
                            if (widget.medications.isEmpty)
                              Text("No active medications found.", style: AppTextStyles.caption.copyWith(color: AppColors.textDark))
                            else
                              ...widget.medications.map((m) => _medicationItem(m)),

                            const SizedBox(height: 25),
                            _sectionHeader("AI Insights"),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                              ),
                              child: Text(
                                d.aiInsights ?? "Based on clinical records, patient shows consistent progress. Advised to continue current medication and maintain follow-up schedule.",
                                style: AppTextStyles.body.copyWith(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.tealDark),
                              ),
                            ),

                            const SizedBox(height: 20),
                            _sectionHeader("Physician Notes"),
                            const SizedBox(height: 10),
                            Text(d.notes ?? "--", style: AppTextStyles.body.copyWith(fontSize: 12)),

                            const SizedBox(height: 60),
                            Center(
                              child: Column(
                                children: [
                                  Container(height: 1, width: 150, color: Colors.grey[400]),
                                  const SizedBox(height: 5),
                                  Text("AUTHORIZED SIGNATORY", style: AppTextStyles.captionBold.copyWith(fontSize: 9, color: AppColors.black)),
                                  const SizedBox(height: 40),
                                  Text("*** END OF OFFICIAL REPORT ***", style: AppTextStyles.captionBold.copyWith(fontSize: 8, color: Colors.grey, letterSpacing: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Action Button
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)],
              ),
              child: ElevatedButton.icon(
                onPressed: _handlePrint,
                icon: _isPrinting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_rounded, color: Colors.white),
                label: Text(_isPrinting ? "PREPARING..." : "PRINT REPORT", style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealDark));

  Widget _detailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.black, fontWeight: FontWeight.w800))),
          Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: isBold ? FontWeight.w600 : FontWeight.w400, color: valueColor ?? AppColors.black))),
        ],
      ),
    );
  }

  Widget _medicationItem(Medication m) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 6, color: AppColors.teal),
        const SizedBox(width: 10),
        Expanded(child: Text(m.name ?? "--", style: AppTextStyles.bodyBold.copyWith(fontSize: 12))),
        Text("${m.frequency ?? "--"} | ${m.timing ?? "--"}", style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    ),
  );
}
