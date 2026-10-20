import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healora/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healora/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healora/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:healora/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:healora/app/core/Util/image_pick_helper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/records_controller.dart';
import 'add_medication_screen.dart';
import 'package:healora/app/core/Util/app_toast.dart';

class AiPrescriptionScreen extends StatefulWidget {
  final String? diseaseUuid;
  final String? appointmentUuid;
  const AiPrescriptionScreen({super.key, this.diseaseUuid, this.appointmentUuid});

  @override
  State<AiPrescriptionScreen> createState() => _AiPrescriptionScreenState();
}

class _AiPrescriptionScreenState extends State<AiPrescriptionScreen>
    with SingleTickerProviderStateMixin {
  final RecordsController controller = Get.find<RecordsController>();
  int _step = 0; // 0=Capture, 1=Reading, 2=Review, 3=Done
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  File? _image;

  Map<String, dynamic>? _scanResult;

  final _doctorCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _prescribedOnCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  /// Editable medication rows extracted by AI (or added manually).
  final List<Map<String, dynamic>> _medications = [];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _doctorCtrl.dispose();
    _hospitalCtrl.dispose();
    _prescribedOnCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePickHelper.pick(source: source);
    if (file == null) return;

    setState(() {
      _image = file;
      _step = 1;
    });

    final result = await controller.scanPrescription(
      _image!.path,
      diseaseUuid: widget.diseaseUuid,
      appointmentUuid: widget.appointmentUuid,
    );

    if (result != null) {
      _applyScanResult(result);
      setState(() => _step = 2);
    } else {
      Get.snackbar(
        'Alert',
        'Prescription uploaded but AI extraction failed. Please review and enter details manually.',
        backgroundColor: AppColors.orange,
        colorText: Colors.white,
      );
      setState(() => _step = 2);
    }
  }

  void _rescan() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EBE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Re-scan prescription', style: AppTextStyles.heading3),
              const SizedBox(height: 6),
              Text(
                'Current review will be replaced with a new scan.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomPrimaryButton(
                      text: '📷 Camera',
                      color: AppColors.primary,
                      onTap: () {
                        Get.back();
                        _resetForRescan();
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomOutlineButton(
                      text: '📁 Upload',
                      onTap: () {
                        Get.back();
                        _resetForRescan();
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _resetForRescan() {
    setState(() {
      _image = null;
      _scanResult = null;
      _medications.clear();
      _doctorCtrl.clear();
      _hospitalCtrl.clear();
      _prescribedOnCtrl.clear();
      _notesCtrl.clear();
      _step = 0;
    });
  }

  void _applyScanResult(Map<String, dynamic> result) {
    _scanResult = result;
    _doctorCtrl.text = result['doctor_name']?.toString() ?? '';
    _hospitalCtrl.text = result['hospital_name']?.toString() ?? '';
    _prescribedOnCtrl.text = result['prescribed_on']?.toString() ?? '';
    _notesCtrl.text = result['notes']?.toString() ?? '';

    _medications.clear();
    final rawMeds = result['medications'];
    if (rawMeds is List) {
      for (final m in rawMeds) {
        if (m is Map) {
          _medications.add(Map<String, dynamic>.from(m));
        }
      }
    }
  }

  bool _validateReview() {
    final doctor = _doctorCtrl.text.trim();
    final hospital = _hospitalCtrl.text.trim();

    if (doctor.isEmpty && hospital.isEmpty && _medications.isEmpty) {
      AppToast.showToast(
        msg: 'Add doctor/hospital details or at least one medicine before continuing.',
      );
      return false;
    }

    for (var i = 0; i < _medications.length; i++) {
      final name = (_medications[i]['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        AppToast.showToast(
          msg: 'Medication ${i + 1}: name is required. Edit or delete it.',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _saveAndLink() async {
    if (!_validateReview()) return;

    if (_scanResult == null ||
        (_scanResult!['uuid']?.toString().isEmpty ?? true)) {
      // No backend slip — still allow moving forward with reviewed local data.
      setState(() => _step = 3);
      return;
    }

    final success = await controller.reviewPrescription(
      _scanResult!['uuid'].toString(),
      {
        'doctor_name': _doctorCtrl.text.trim(),
        'hospital_name': _hospitalCtrl.text.trim(),
        'prescribed_on': _prescribedOnCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'medications': _medications
            .map((m) => Map<String, dynamic>.from(m))
            .toList(),
      },
      diseaseUuid: widget.diseaseUuid,
    );

    if (success) {
      // Keep reviewed meds on scanResult for the Done step CTA.
      _scanResult = {
        ..._scanResult!,
        'doctor_name': _doctorCtrl.text.trim(),
        'hospital_name': _hospitalCtrl.text.trim(),
        'prescribed_on': _prescribedOnCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'medications':
            _medications.map((m) => Map<String, dynamic>.from(m)).toList(),
      };
      setState(() => _step = 3);
    } else {
      Get.snackbar('Error', 'Failed to save prescription details');
    }
  }

  Future<void> _editMedication(int index) async {
    final edited = await _showMedicationEditor(
      initial: Map<String, dynamic>.from(_medications[index]),
      title: 'Edit medication',
    );
    if (edited == null) return;
    setState(() => _medications[index] = edited);
  }

  Future<void> _addMedication() async {
    final added = await _showMedicationEditor(
      initial: {
        'name': '',
        'strength': '',
        'dosage': '',
        'frequency': '',
        'instructions': '',
      },
      title: 'Add medication',
    );
    if (added == null) return;
    setState(() => _medications.add(added));
  }

  void _deleteMedication(int index) {
    Get.dialog(
      AlertDialog(
        title: const Text('Remove medicine?'),
        content: Text(
          'Remove "${_medications[index]['name'] ?? 'this medicine'}" from the review list?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              setState(() => _medications.removeAt(index));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showMedicationEditor({
    required Map<String, dynamic> initial,
    required String title,
  }) async {
    final nameCtrl =
        TextEditingController(text: initial['name']?.toString() ?? '');
    final strengthCtrl =
        TextEditingController(text: initial['strength']?.toString() ?? '');
    final dosageCtrl =
        TextEditingController(text: initial['dosage']?.toString() ?? '');
    final frequencyCtrl =
        TextEditingController(text: initial['frequency']?.toString() ?? '');
    final instructionsCtrl =
        TextEditingController(text: initial['instructions']?.toString() ?? '');

    final result = await Get.bottomSheet<Map<String, dynamic>>(
      SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(Get.context!).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3EBE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(title, style: AppTextStyles.heading3),
                const SizedBox(height: 14),
                CustomTextField(
                  hint: 'Medicine name *',
                  controller: nameCtrl,
                  prefixIcon: Icons.medication_outlined,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hint: 'Strength (e.g. 650mg)',
                  controller: strengthCtrl,
                  prefixIcon: Icons.science_outlined,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hint: 'Dosage (e.g. 1 tablet)',
                  controller: dosageCtrl,
                  prefixIcon: Icons.format_list_numbered,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hint: 'Frequency (e.g. 1-0-1)',
                  controller: frequencyCtrl,
                  prefixIcon: Icons.schedule_outlined,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hint: 'Instructions (optional)',
                  controller: instructionsCtrl,
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomOutlineButton(
                        text: 'Cancel',
                        onTap: () => Get.back(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomPrimaryButton(
                        text: 'Save',
                        color: AppColors.tealDark,
                        onTap: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            AppToast.showToast(
                                msg: 'Medicine name is required.');
                            return;
                          }
                          final updated = Map<String, dynamic>.from(initial);
                          updated['name'] = name;
                          updated['strength'] = strengthCtrl.text.trim();
                          updated['dosage'] = dosageCtrl.text.trim();
                          updated['frequency'] = frequencyCtrl.text.trim();
                          updated['instructions'] =
                              instructionsCtrl.text.trim();
                          Get.back(result: updated);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    nameCtrl.dispose();
    strengthCtrl.dispose();
    dosageCtrl.dispose();
    frequencyCtrl.dispose();
    instructionsCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(
        title: '🤖 AI Prescription Reader',
        showBack: true,
      ),
      body: Obx(
        () => Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: List.generate(4, (i) {
                      final labels = ['Capture', 'AI Reads', 'Review', 'Save'];
                      final colors = [
                        AppColors.primary,
                        AppColors.teal,
                        AppColors.orange,
                        AppColors.green,
                      ];
                      final isDone = _step > i;
                      final isActive = _step == i;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isDone || isActive
                                          ? colors[i]
                                          : AppColors.bgCardNavy,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isActive
                                            ? colors[i]
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: isDone
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 16)
                                          : Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                color: isActive
                                                    ? Colors.white
                                                    : AppColors.textMuted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    labels[i],
                                    style: AppTextStyles.caption.copyWith(
                                      color: isActive
                                          ? colors[i]
                                          : AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < 3)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  margin: const EdgeInsets.only(bottom: 18),
                                  color: _step > i
                                      ? colors[i]
                                      : AppColors.border,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Expanded(child: _buildStepContent()),
                  const SizedBox(height: 16),
                  if (_step == 0)
                    Row(
                      children: [
                        Expanded(
                          child: CustomPrimaryButton(
                            text: '📷 Camera',
                            color: AppColors.primary,
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomOutlineButton(
                            text: '📁 Upload',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    )
                  else if (_step == 2)
                    Row(
                      children: [
                        Expanded(
                          child: CustomOutlineButton(
                            text: 'Re-scan',
                            onTap: _rescan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomPrimaryButton(
                            text: 'Validate & Continue',
                            color: AppColors.green,
                            icon: Icons.verified_outlined,
                            onTap: _saveAndLink,
                          ),
                        ),
                      ],
                    )
                  else if (_step == 3)
                    Column(
                      children: [
                        CustomPrimaryButton(
                          text: 'Done',
                          color: AppColors.teal,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 10),
                        CustomOutlineButton(
                          text: 'Re-scan another slip',
                          onTap: _rescan,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (controller.isLoading.value)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return const _StepCapture();
      case 1:
        return _StepReading(pulse: _pulse, image: _image);
      case 2:
        return _StepReview(
          image: _image,
          doctorCtrl: _doctorCtrl,
          hospitalCtrl: _hospitalCtrl,
          prescribedOnCtrl: _prescribedOnCtrl,
          notesCtrl: _notesCtrl,
          medications: _medications,
          onEditMed: _editMedication,
          onDeleteMed: _deleteMedication,
          onAddMed: _addMedication,
        );
      case 3:
        return _StepSaveDone(
          scanResult: _scanResult,
          diseaseUuid: widget.diseaseUuid,
          medications: _medications,
        );
      default:
        return const SizedBox();
    }
  }
}

// ── Step 0: Camera viewfinder mock ────────────────────────────────────────────
class _StepCapture extends StatelessWidget {
  const _StepCapture();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgDeepNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.document_scanner_outlined,
                          color: AppColors.teal, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Position prescription\nwithin the frame',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Positioned(
                    top: 20, left: 20, child: _CornerMark(topLeft: true)),
                const Positioned(
                    top: 20, right: 20, child: _CornerMark()),
                const Positioned(
                    bottom: 20,
                    left: 20,
                    child: _CornerMark(topLeft: true, bottom: true)),
                const Positioned(
                    bottom: 20, right: 20, child: _CornerMark(bottom: true)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        McCard(
          color: AppColors.bgCardDark,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppColors.orange, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Supports Hindi & English prescriptions. AI reads doctor name, medicines, dosage & follow-up.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CornerMark extends StatelessWidget {
  final bool topLeft;
  final bool bottom;
  const _CornerMark({this.topLeft = false, this.bottom = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: CustomPaint(
          painter: _CornerPainter(topLeft: topLeft, bottom: bottom)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, bottom;
  const _CornerPainter({required this.topLeft, required this.bottom});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (!topLeft && !bottom) {
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, 20), p);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - 20, 0), p);
    } else if (topLeft && !bottom) {
      canvas.drawLine(const Offset(0, 0), const Offset(0, 20), p);
      canvas.drawLine(const Offset(0, 0), const Offset(20, 0), p);
    } else if (topLeft && bottom) {
      canvas.drawLine(
          Offset(0, size.height), Offset(0, size.height - 20), p);
      canvas.drawLine(
          Offset(0, size.height), Offset(20, size.height), p);
    } else {
      canvas.drawLine(Offset(size.width, size.height),
          Offset(size.width, size.height - 20), p);
      canvas.drawLine(Offset(size.width, size.height),
          Offset(size.width - 20, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Step 1: AI Reading ────────────────────────────────────────────────────────
class _StepReading extends StatelessWidget {
  final Animation<double> pulse;
  final File? image;
  const _StepReading({required this.pulse, this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (image != null)
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                  image: FileImage(image!), fit: BoxFit.cover),
            ),
          ),
        ScaleTransition(
          scale: pulse,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: const Icon(Icons.auto_fix_high,
                color: AppColors.teal, size: 36),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reading prescription with AI...',
          style: AppTextStyles.heading3.copyWith(color: AppColors.accentTeal),
        ),
        const SizedBox(height: 32),
        ...['Doctor', 'Date', 'Medicines', 'Follow-up'].map(
          (field) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCardNavy,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text('$field:', style: AppTextStyles.captionBold),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.6,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Extracting...',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.teal)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Review / edit / delete / validate ─────────────────────────────────
class _StepReview extends StatelessWidget {
  final File? image;
  final TextEditingController doctorCtrl;
  final TextEditingController hospitalCtrl;
  final TextEditingController prescribedOnCtrl;
  final TextEditingController notesCtrl;
  final List<Map<String, dynamic>> medications;
  final Future<void> Function(int index) onEditMed;
  final void Function(int index) onDeleteMed;
  final VoidCallback onAddMed;

  const _StepReview({
    required this.image,
    required this.doctorCtrl,
    required this.hospitalCtrl,
    required this.prescribedOnCtrl,
    required this.notesCtrl,
    required this.medications,
    required this.onEditMed,
    required this.onDeleteMed,
    required this.onAddMed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (image != null)
          Container(
            height: 110,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                  image: FileImage(image!), fit: BoxFit.cover),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Review & correct', style: AppTextStyles.heading3),
                  const SizedBox(height: 2),
                  Text(
                    'Edit fields, remove wrong meds, then validate to continue.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textGray),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${medications.length} meds',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.orange, fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReviewSection(
          title: 'Prescription details',
          icon: Icons.local_hospital_outlined,
          child: Column(
            children: [
              CustomTextField(
                hint: 'Doctor name',
                controller: doctorCtrl,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                hint: 'Hospital / clinic',
                controller: hospitalCtrl,
                prefixIcon: Icons.apartment_outlined,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                hint: 'Prescribed on (YYYY-MM-DD)',
                controller: prescribedOnCtrl,
                prefixIcon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                hint: 'Notes (optional)',
                controller: notesCtrl,
                prefixIcon: Icons.notes_outlined,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ReviewSection(
          title: 'Medications',
          icon: Icons.medication_outlined,
          trailing: TextButton.icon(
            onPressed: onAddMed,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.tealDark,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          child: medications.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3EBE7)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.medication_liquid_outlined,
                          color: AppColors.textGray, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'No medicines extracted. Add them manually.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textGray),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < medications.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _MedicationReviewCard(
                        index: i,
                        med: medications[i],
                        onEdit: () => onEditMed(i),
                        onDelete: () => onDeleteMed(i),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 8),
        McCard(
          color: AppColors.bgCardDark,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppColors.teal, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Validate checks required medicine names and ensures the slip has useful details before saving.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.tealDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.textDark,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MedicationReviewCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> med;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationReviewCard({
    required this.index,
    required this.med,
    required this.onEdit,
    required this.onDelete,
  });

  String get _name => (med['name'] ?? '').toString().trim();
  bool get _hasName => _name.isNotEmpty;

  String get _subtitle {
    final parts = <String>[
      if ((med['strength'] ?? '').toString().trim().isNotEmpty)
        med['strength'].toString(),
      if ((med['dosage'] ?? '').toString().trim().isNotEmpty)
        med['dosage'].toString(),
      if ((med['frequency'] ?? '').toString().trim().isNotEmpty)
        med['frequency'].toString(),
    ];
    return parts.isEmpty ? 'Tap edit to fill dosage details' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasName
            ? const Color(0xFFF3F7F5)
            : AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasName
              ? AppColors.teal.withValues(alpha: 0.25)
              : AppColors.orange.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _hasName ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: _hasName ? AppColors.green : AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasName ? _name : 'Unnamed medicine #${index + 1}',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textGray),
                ),
                if ((med['instructions'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    med['instructions'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.tealDark),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.statusRed),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Saved ─────────────────────────────────────────────────────────────
class _StepSaveDone extends StatelessWidget {
  final Map<String, dynamic>? scanResult;
  final String? diseaseUuid;
  final List<Map<String, dynamic>> medications;

  const _StepSaveDone({
    this.scanResult,
    this.diseaseUuid,
    this.medications = const [],
  });

  @override
  Widget build(BuildContext context) {
    final meds = medications.isNotEmpty
        ? medications
        : ((scanResult?['medications'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.green, size: 40),
                ),
                const SizedBox(height: 12),
                Text('Slip Saved!',
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.green)),
                const SizedBox(height: 6),
                Text('What would you like to do next?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomPrimaryButton(
                        text: '+ Add Meds',
                        color: AppColors.teal,
                        onTap: () {
                          if (meds.isNotEmpty) {
                            Get.off(() => AddMedicationScreen(
                                  diseaseUuid: diseaseUuid,
                                  initialData:
                                      Map<String, dynamic>.from(meds.first),
                                ));
                          } else {
                            Get.off(() =>
                                AddMedicationScreen(diseaseUuid: diseaseUuid));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomPrimaryButton(
                        text: 'Return',
                        color: AppColors.primary,
                        onTap: () => Get.back(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
