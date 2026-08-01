import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:healaura/app/data/models/disease_response_model.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import 'package:healaura/app/modules/profile/controllers/profile_controller.dart';
import 'package:healaura/app/core/theme/app_colors.dart';
import 'package:healaura/app/core/theme/app_text_theme.dart';

class DiseasePdfPreviewScreen extends StatefulWidget {
  final DiseaseResult disease;
  final List<Medication> medications;
  final List<TimelineEvent> timeline;

  const DiseasePdfPreviewScreen({
    super.key,
    required this.disease,
    required this.medications,
    required this.timeline,
  });

  @override
  State<DiseasePdfPreviewScreen> createState() =>
      _DiseasePdfPreviewScreenState();
}

class _DiseasePdfPreviewScreenState extends State<DiseasePdfPreviewScreen> {
  late ProfileController profileCtrl;
  bool _isPrinting = false;
  bool _isSharing = false;
  final GlobalKey _receiptKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
  }

  String get _patientName {
    final name = profileCtrl.fullNameCtrl.text.trim();
    return name.isEmpty ? 'Patient' : name;
  }

  String get _patientId {
    final mobile = profileCtrl.mobileNumber.value.trim();
    if (mobile.isEmpty) return 'HA-000000';
    final tail = mobile.length > 6
        ? mobile.substring(mobile.length - 6)
        : mobile;
    return 'HA-$tail';
  }

  String get _reportId =>
      widget.disease.displayId?.toString().isNotEmpty == true
          ? widget.disease.displayId.toString()
          : 'RPT-${DateFormat('yyMMdd').format(DateTime.now())}';

  Future<Uint8List?> _capturePdfBytes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final boundary =
        _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(pngBytes);
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(12),
        build: (_) =>
            pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
      ),
    );
    return pdf.save();
  }

  Future<void> _handlePrint() async {
    if (_isPrinting || _isSharing) return;
    setState(() => _isPrinting = true);
    try {
      final bytes = await _capturePdfBytes();
      if (bytes == null) throw 'Capture failed';
      await Printing.layoutPdf(
        name: 'Medical_Report_$_reportId',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      Get.snackbar(
        'Print Error',
        'Failed to generate print: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.statusRed,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isPrinting || _isSharing) return;
    setState(() => _isSharing = true);
    try {
      final bytes = await _capturePdfBytes();
      if (bytes == null) throw 'Capture failed';
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'HealAura_Medical_Report_$_reportId.pdf',
      );
    } catch (e) {
      Get.snackbar(
        'Share Error',
        'Failed to share report: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.statusRed,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return AppColors.statusActive;
      case 'monitoring':
      case 'under monitoring':
        return AppColors.statusMonitor;
      case 'resolved':
      case 'in remission':
        return AppColors.statusResolved;
      default:
        return AppColors.tealDark;
    }
  }

  String _fmt(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final d = widget.disease;
    final busy = _isPrinting || _isSharing;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          _Header(
            topPad: top,
            reportId: _reportId,
            onBack: () => Get.back(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  _TipBanner(),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _ReportDocument(
                      disease: d,
                      medications: widget.medications,
                      patientName: _patientName,
                      patientId: _patientId,
                      reportId: _reportId,
                      gender: profileCtrl.selectedGender.value.isEmpty
                          ? '—'
                          : profileCtrl.selectedGender.value,
                      dob: profileCtrl.dobCtrl.text.isEmpty
                          ? '—'
                          : profileCtrl.dobCtrl.text,
                      bloodGroup: profileCtrl.bloodGroup.value.isEmpty
                          ? '—'
                          : profileCtrl.bloodGroup.value,
                      statusColor: _statusColor(d.status),
                      formatDate: _fmt,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: Color(0xFFE3EBE7)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : _handleShare,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.tealDark,
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(
                      _isSharing ? 'Preparing…' : 'Share',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.tealDark,
                      side: BorderSide(
                          color: AppColors.teal.withValues(alpha: 0.45)),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded,
                            color: Colors.white, size: 20),
                    label: Text(
                      _isPrinting ? 'Preparing…' : 'Download',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealDark,
                      disabledBackgroundColor:
                          AppColors.tealDark.withValues(alpha: 0.55),
                      minimumSize: const Size.fromHeight(50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  final String reportId;
  final VoidCallback onBack;

  const _Header({
    required this.topPad,
    required this.reportId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 16, 16),
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
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onBack,
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
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      'Medical Report',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Preview · Download · Share',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Official health summary · ID $reportId',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded,
                color: AppColors.tealDark, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Review the report below, then download or share the PDF.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDocument extends StatelessWidget {
  final DiseaseResult disease;
  final List<Medication> medications;
  final String patientName;
  final String patientId;
  final String reportId;
  final String gender;
  final String dob;
  final String bloodGroup;
  final Color statusColor;
  final String Function(String?) formatDate;

  const _ReportDocument({
    required this.disease,
    required this.medications,
    required this.patientName,
    required this.patientId,
    required this.reportId,
    required this.gender,
    required this.dob,
    required this.bloodGroup,
    required this.statusColor,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final d = disease;
    final generatedOn =
        DateFormat('dd MMM yyyy · HH:mm').format(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EBE7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document brand header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      const Text(
                        'HealAura',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Clinical Condition Report',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      reportId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      generatedOn,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle('Patient information'),
                const SizedBox(height: 10),
                _InfoTable(
                  rows: [
                    ('Full name', patientName),
                    ('Patient ID', patientId),
                    ('Gender', gender),
                    ('Date of birth', dob),
                    ('Blood group', bloodGroup),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle('Condition'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: (d.status ?? '—').toUpperCase(),
                            color: statusColor,
                          ),
                          if (d.conditionType != null &&
                              d.conditionType!.isNotEmpty)
                            _Badge(
                              label: d.conditionType!.toUpperCase(),
                              color: AppColors.tealDark,
                              soft: true,
                            ),
                          if (d.severity != null && d.severity!.isNotEmpty)
                            _Badge(
                              label: d.severity!.toUpperCase(),
                              color: AppColors.orange,
                              soft: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _InfoTable(
                  rows: [
                    ('ICD code', d.icdCode ?? '—'),
                    ('Category', d.category ?? '—'),
                    (
                      'Affected area',
                      (d.bodyParts ?? []).isEmpty
                          ? '—'
                          : d.bodyParts!.join(', ')
                    ),
                    ('Hereditary', d.hereditary ?? '—'),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle('Timeline'),
                const SizedBox(height: 10),
                _InfoTable(
                  rows: [
                    ('Diagnosed on', formatDate(d.diagnosedOn)),
                    ('Recovered on', formatDate(d.recoveredOn)),
                    ('Next follow-up', formatDate(d.nextFollowUpOn)),
                  ],
                ),
                if (d.hospitalizationRequired == true) ...[
                  const SizedBox(height: 18),
                  _SectionTitle('Hospitalization'),
                  const SizedBox(height: 10),
                  _InfoTable(
                    rows: [
                      ('Admitted on', formatDate(d.admittedOn)),
                      ('Discharged on', formatDate(d.dischargedOn)),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _SectionTitle('Medications'),
                const SizedBox(height: 10),
                if (medications.isEmpty)
                  Text(
                    'No active medications linked to this condition.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...medications.map((m) => _MedRow(med: m)),
                const SizedBox(height: 18),
                _SectionTitle('AI insights'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    d.aiInsights ??
                        'Upload prescriptions or bills to generate AI insights for this condition.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12.5,
                      height: 1.45,
                      fontStyle: d.aiInsights == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle('Physician notes'),
                const SizedBox(height: 10),
                Text(
                  (d.notes != null && d.notes!.trim().isNotEmpty)
                      ? d.notes!
                      : '—',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 1,
                        color: const Color(0xFFD5E0DB),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AUTHORIZED SUMMARY',
                        style: AppTextStyles.captionBold.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Generated securely by HealAura',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.tealDark,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: AppColors.tealDark,
          ),
        ),
      ],
    );
  }
}

class _InfoTable extends StatelessWidget {
  final List<(String, String)> rows;
  const _InfoTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((r) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  r.$1,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textGray,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  r.$2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool soft;

  const _Badge({
    required this.label,
    required this.color,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: soft ? color.withValues(alpha: 0.10) : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MedRow extends StatelessWidget {
  final Medication med;
  const _MedRow({required this.med});

  @override
  Widget build(BuildContext context) {
    final detail = med.subtitle.isNotEmpty
        ? med.subtitle
        : [
            if (med.frequencyDisplay.isNotEmpty) med.frequencyDisplay,
            if (med.timing.isNotEmpty) med.timing,
          ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.tealDark,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                med.name.isEmpty ? '—' : med.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Flexible(
              child: Text(
                detail.isEmpty ? '—' : detail,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
