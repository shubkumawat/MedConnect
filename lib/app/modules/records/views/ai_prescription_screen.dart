import 'dart:io';
import 'package:flutter/material.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../controllers/records_controller.dart';
import 'add_medication_screen.dart';

class AiPrescriptionScreen extends StatefulWidget {
  final String? diseaseUuid;
  const AiPrescriptionScreen({super.key, this.diseaseUuid});

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

  final Map<String, String> _extractedData = {};
  final Map<String, bool> _confidence = {};

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulse = Tween(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _step = 1;
      });
      
      var result = await controller.scanPrescription(_image!.path, diseaseUuid: widget.diseaseUuid);
      
      if (result != null) {
        setState(() {
          _scanResult = result;
          _extractedData.clear();
          _extractedData['Doctor'] = result['doctor_name'] ?? "";
          _extractedData['Hospital'] = result['hospital_name'] ?? "";
          _extractedData['Prescribed On'] = result['prescribed_on'] ?? "";
          _extractedData['Notes'] = result['notes'] ?? "";
          
          if (result['medications'] != null && (result['medications'] as List).isNotEmpty) {
             List meds = result['medications'] as List;
             for (int i=0; i<meds.length; i++) {
               var m = meds[i];
               _extractedData['Medication ${i+1}'] = "${m['name']} (${m['dosage'] ?? ''})";
             }
          }

          // Confidence indicators
          _extractedData.forEach((key, value) {
            _confidence[key] = value.isNotEmpty;
          });

          _step = 2;
        });
      } else {
        Get.snackbar('Alert', 'Prescription uploaded but AI extraction failed. Please review and enter details manually.',
          backgroundColor: AppColors.orange, colorText: Colors.white);
        setState(() => _step = 2);
      }
    }
  }

  Future<void> _saveAndLink() async {
    if (_scanResult == null) {
       setState(() => _step = 3);
       return;
    }

    bool success = await controller.reviewPrescription(
      _scanResult!['uuid'],
      {
        "doctor_name": _extractedData['Doctor'] ?? "",
        "hospital_name": _extractedData['Hospital'] ?? "",
        "notes": _extractedData['Notes'] ?? "",
      },
      diseaseUuid: widget.diseaseUuid,
    );

    if (success) {
      setState(() => _step = 3);
    } else {
      Get.snackbar('Error', 'Failed to save prescription details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: '🤖 AI Prescription Reader', showBack: true),
      body: Obx(() => Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Step indicators
                Row(
                  children: List.generate(4, (i) {
                    final labels = ['Capture', 'AI Reads', 'Review', 'Save'];
                    final colors = [AppColors.primary, AppColors.teal, AppColors.orange, AppColors.green];
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
                                    color: isDone || isActive ? colors[i] : AppColors.bgCardNavy,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isActive ? colors[i] : AppColors.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: isDone
                                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                                        : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isActive ? Colors.white : AppColors.textMuted,
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
                                    color: isActive ? colors[i] : AppColors.textMuted,
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
                                color: _step > i ? colors[i] : AppColors.border,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Step content
                Expanded(child: _buildStepContent()),

                const SizedBox(height: 16),

                // CTA
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
                  CustomPrimaryButton(
                    text: 'Looks Good — Save & Link',
                    color: AppColors.green,
                    icon: Icons.check_circle_outline,
                    onTap: _saveAndLink,
                  )
                else if (_step == 3)
                    CustomPrimaryButton(
                      text: 'Done',
                      color: AppColors.teal,
                      onTap: () => Navigator.pop(context),
                    ),
              ],
            ),
          ),
          if (controller.isLoading.value)
            const Center(child: CircularProgressIndicator()),
        ],
      )),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _StepCapture();
      case 1:
        return _StepReading(pulse: _pulse, image: _image);
      case 2:
        return _StepReview(data: _extractedData, confidence: _confidence, image: _image);
      case 3:
        return _StepSaveDone(scanResult: _scanResult);
      default:
        return const SizedBox();
    }
  }
}

// ── Step 0: Camera viewfinder mock ────────────────────────────────────────────
class _StepCapture extends StatelessWidget {
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
                      const Icon(Icons.document_scanner_outlined, color: AppColors.teal, size: 64),
                      const SizedBox(height: 16),
                      Text('Position prescription\nwithin the frame', style: AppTextStyles.body, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                // Corner markers
                Positioned(top: 20, left: 20, child: _CornerMark(topLeft: true)),
                Positioned(top: 20, right: 20, child: _CornerMark(topLeft: false)),
                Positioned(bottom: 20, left: 20, child: _CornerMark(topLeft: true, bottom: true)),
                Positioned(bottom: 20, right: 20, child: _CornerMark(bottom: true)),
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
              const Icon(Icons.lightbulb_outline, color: AppColors.orange, size: 18),
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
      child: CustomPaint(painter: _CornerPainter(topLeft: topLeft, bottom: bottom)),
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
      canvas.drawLine(Offset(0, 0), Offset(0, 20), p);
      canvas.drawLine(Offset(0, 0), Offset(20, 0), p);
    } else if (topLeft && bottom) {
      canvas.drawLine(Offset(0, size.height), Offset(0, size.height - 20), p);
      canvas.drawLine(Offset(0, size.height), Offset(20, size.height), p);
    } else {
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - 20), p);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width - 20, size.height), p);
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
              image: DecorationImage(image: FileImage(image!), fit: BoxFit.cover),
            ),
          ),
        ScaleTransition(
          scale: pulse,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: const Icon(Icons.auto_fix_high, color: AppColors.teal, size: 36),
          ),
        ),
        const SizedBox(height: 24),
        Text('Reading prescription with AI...', style: AppTextStyles.heading3.copyWith(color: AppColors.accentTeal)),
        const SizedBox(height: 32),
        ...['Doctor', 'Date', 'Medicines', 'Follow-up'].map((field) => Container(
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
                        color: AppColors.teal.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Extracting...', style: AppTextStyles.caption.copyWith(color: AppColors.teal)),
            ],
          ),
        )),
      ],
    );
  }
}

// ── Step 2: Review extracted data ─────────────────────────────────────────────
class _StepReview extends StatelessWidget {
  final Map<String, String> data;
  final Map<String, bool> confidence;
  final File? image;
  const _StepReview({required this.data, required this.confidence, this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (image != null)
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: FileImage(image!), fit: BoxFit.cover),
            ),
          ),
        Text('Review Extracted Data', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text('Correct anything highlighted in orange', style: AppTextStyles.caption),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: data.entries.map((e) {
              final ok = confidence[e.key] ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ok ? AppColors.bgCardNavy : AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ok ? AppColors.teal.withOpacity(0.4) : AppColors.orange),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: AppTextStyles.caption),
                          Text(e.value, style: AppTextStyles.bodyBold),
                        ],
                      ),
                    ),
                    Icon(
                      ok ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: ok ? AppColors.green : AppColors.orange,
                      size: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Step 3: Saved ─────────────────────────────────────────────────────────────
class _StepSaveDone extends StatelessWidget {
  final Map<String, dynamic>? scanResult;
  const _StepSaveDone({this.scanResult});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.green.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: AppColors.green, size: 48),
        ),
        const SizedBox(height: 20),
        Text('Slip Saved!', style: AppTextStyles.heading2.copyWith(color: AppColors.green)),
        const SizedBox(height: 8),
        Text('What would you like to do next?', style: AppTextStyles.body),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: CustomPrimaryButton(
                text: '+ Add Meds',
                color: AppColors.teal,
                onTap: () {
                  final medications = scanResult?['medications'] as List?;
                  if (medications != null && medications.isNotEmpty) {
                    Get.off(() => AddMedicationScreen(initialData: medications[0]));
                  } else {
                    Get.off(() => const AddMedicationScreen());
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: CustomPrimaryButton(text: 'Return', color: AppColors.primary, onTap: () => Get.back())),
          ],
        ),
        const SizedBox(height: 10),
        // CustomOutlineButton(text: '⏰ Set Reminders', onTap: () => Get.off(() => const NotificationsScreen())),
      ],
    );
  }
}
