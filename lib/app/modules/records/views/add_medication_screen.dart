import 'package:flutter/material.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../services/medication_ocr_service.dart';
import '../utils/medication_ocr_parser.dart';

class AddMedicationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddMedicationScreen({super.key, this.initialData});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _medNameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _prescribedByCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  final MedicationOcrService _ocrService = MedicationOcrService();

  String? _dosageUnit = 'mg';
  String? _form;
  String? _frequency;
  String? _timing;
  String? _linkedDisease;
  bool _isOngoing = false;
  bool _reminderEnabled = true;
  bool _isLoading = false;
  bool _isScanning = false;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // reminder times
  final List<String> _reminderTimes = ['8:00 AM'];

  final _forms = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Inhaler', 'Topical', 'Patch'];
  final _frequencies = ['Once daily', 'Twice daily', '3x daily', '4x daily', 'Every 6 hours', 'Every 8 hours', 'SOS'];
  final _timings = ['Before Food', 'After Food', 'With Food', 'Bedtime', 'Empty Stomach'];
  final _units = ['mg', 'ml', 'IU', 'g'];
  final _diseases = ['Type 2 Diabetes', 'Hypertension', 'Hernia (Inguinal)'];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _medNameCtrl.text = widget.initialData!['name'] ?? "";
      _dosageCtrl.text = widget.initialData!['dosage'] ?? "";
      _frequency = widget.initialData!['frequency'];
      _timing = widget.initialData!['timing'];
      _form = widget.initialData!['form'];
    }
  }

  @override
  void dispose() {
    _medNameCtrl.dispose();
    _genericCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    _prescribedByCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = picked;
          _startDateCtrl.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        } else {
          _selectedEndDate = picked;
          _endDateCtrl.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      });
    }
  }

  Future<void> _showScanSourceSheet() async {
    if (_isScanning) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Scan Medication', style: AppTextStyles.heading3),
                const SizedBox(height: 6),
                Text(
                  'Capture a medicine strip, box, or prescription',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1A1B9E8E),
                    child: Icon(Icons.photo_camera_outlined, color: AppColors.teal),
                  ),
                  title: Text('Take Photo', style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
                  subtitle: Text('Use camera to scan', style: AppTextStyles.caption),
                  onTap: () {
                    Navigator.pop(ctx);
                    _runScan(MedicationScanSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1AE07B2A),
                    child: Icon(Icons.photo_library_outlined, color: AppColors.orange),
                  ),
                  title: Text('Choose from Gallery', style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
                  subtitle: Text('Pick an existing image', style: AppTextStyles.caption),
                  onTap: () {
                    Navigator.pop(ctx);
                    _runScan(MedicationScanSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runScan(MedicationScanSource source) async {
    setState(() => _isScanning = true);

    final outcome = await _ocrService.scan(source: source);

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (outcome.cancelled) return;

    if (!outcome.isSuccess) {
      Get.snackbar(
        'Scan Failed',
        outcome.errorMessage ?? 'Unable to scan medication.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    _applyOcrResult(outcome.result!);
    Get.snackbar(
      'Scan Complete',
      'Detected fields were filled. Review and edit before saving.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.teal,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  /// Fills only empty fields so existing manual input is preserved.
  void _applyOcrResult(MedicationOcrResult result) {
    setState(() {
      if (_medNameCtrl.text.trim().isEmpty && (result.name?.isNotEmpty ?? false)) {
        _medNameCtrl.text = result.name!;
      }
      if (_genericCtrl.text.trim().isEmpty && (result.genericName?.isNotEmpty ?? false)) {
        _genericCtrl.text = result.genericName!;
      }
      if (_dosageCtrl.text.trim().isEmpty && (result.dosage?.isNotEmpty ?? false)) {
        _dosageCtrl.text = result.dosage!;
        if (result.dosageUnit != null && _units.contains(result.dosageUnit)) {
          _dosageUnit = result.dosageUnit;
        }
      }
      if (_form == null && result.form != null && _forms.contains(result.form)) {
        _form = result.form;
      }
      if (_frequency == null &&
          result.frequency != null &&
          _frequencies.contains(result.frequency)) {
        _frequency = result.frequency;
      }
      if (_timing == null && result.timing != null && _timings.contains(result.timing)) {
        _timing = result.timing;
      }
      if (_instructionsCtrl.text.trim().isEmpty &&
          (result.instructions?.isNotEmpty ?? false)) {
        _instructionsCtrl.text = result.instructions!;
      }

      // Duration → end date when start is set (or today), without clearing existing end date
      if (_endDateCtrl.text.trim().isEmpty &&
          !_isOngoing &&
          (result.duration?.isNotEmpty ?? false)) {
        final start = _selectedStartDate ?? DateTime.now();
        final end = _addDuration(start, result.duration!);
        if (end != null) {
          _selectedStartDate ??= start;
          if (_startDateCtrl.text.trim().isEmpty) {
            _startDateCtrl.text =
                "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
          }
          _selectedEndDate = end;
          _endDateCtrl.text =
              "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";
        }
      }
    });
  }

  DateTime? _addDuration(DateTime start, String duration) {
    final match = RegExp(r'(\d+)\s*(day|days|week|weeks|month|months|yr|year|years)',
            caseSensitive: false)
        .firstMatch(duration.toLowerCase());
    if (match == null) return null;
    final n = int.tryParse(match.group(1) ?? '') ?? 0;
    if (n <= 0) return null;
    final unit = match.group(2)!;
    if (unit.startsWith('day')) return start.add(Duration(days: n));
    if (unit.startsWith('week')) return start.add(Duration(days: n * 7));
    if (unit.startsWith('month')) {
      return DateTime(start.year, start.month + n, start.day);
    }
    if (unit.startsWith('yr') || unit.startsWith('year')) {
      return DateTime(start.year + n, start.month, start.day);
    }
    return null;
  }

  bool _validate() {
    if (_medNameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a medication name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: '💊 Add Medication', showBack: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScanButton(),
                const SizedBox(height: 20),

                // ── Drug Info ─────────────────────────────────────────────
                _SectionBadge('Drug Info', AppColors.teal),
                const SizedBox(height: 14),

                CustomTextField(
                  hint: 'Medication Name (drug search)',
                  controller: _medNameCtrl,
                  prefixIcon: Icons.medication_outlined,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: 'Generic Name (auto-fill)',
                  controller: _genericCtrl,
                  prefixIcon: Icons.science_outlined,
                ),
                const SizedBox(height: 12),

                // Dosage row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        hint: 'Dosage',
                        controller: _dosageCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.format_list_numbered,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgCardNavy,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _dosageUnit,
                            dropdownColor: AppColors.bgCardNavy,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                            style: AppTextStyles.body.copyWith(color: AppColors.textTail),
                            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) => setState(() => _dosageUnit = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                McDropdown(hint: 'Dosage Form', value: _form, items: _forms, onChanged: (v) => setState(() => _form = v)),
                const SizedBox(height: 12),

                McDropdown(hint: 'Frequency', value: _frequency, items: _frequencies, onChanged: (v) => setState(() => _frequency = v)),
                const SizedBox(height: 12),

                McDropdown(hint: 'Timing', value: _timing, items: _timings, onChanged: (v) => setState(() => _timing = v)),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: 'Instructions (optional)',
                  controller: _instructionsCtrl,
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                McDivider(),

                // ── Schedule & Link ───────────────────────────────────────
                _SectionBadge('Schedule & Link', AppColors.primary),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            hint: 'Start Date',
                            controller: _startDateCtrl,
                            prefixIcon: Icons.calendar_today_outlined,
                            readOnly: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _isOngoing
                          ? Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.teal.withOpacity(0.4)),
                              ),
                              child: Center(child: Text('Ongoing', style: AppTextStyles.tealLabel.copyWith(fontSize: 14))),
                            )
                          : GestureDetector(
                              onTap: () => _selectDate(context, false),
                              child: AbsorbPointer(
                                child: CustomTextField(
                                  hint: 'End Date',
                                  controller: _endDateCtrl,
                                  prefixIcon: Icons.event_outlined,
                                  readOnly: true,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Ongoing toggle
                Row(
                  children: [
                    Checkbox(
                      value: _isOngoing,
                      onChanged: (v) => setState(() => _isOngoing = v ?? false),
                      activeColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    Text('Mark as Ongoing medication', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: 'Prescribed By (doctor search)',
                  controller: _prescribedByCtrl,
                  prefixIcon: Icons.person_pin_outlined,
                ),
                const SizedBox(height: 12),

                McDropdown(
                  hint: 'Linked Disease',
                  value: _linkedDisease,
                  items: _diseases,
                  onChanged: (v) => setState(() => _linkedDisease = v),
                ),

                const SizedBox(height: 20),
                McDivider(),

                // ── Reminders ─────────────────────────────────────────────
                _SectionBadge('Reminders', AppColors.orange),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _reminderEnabled ? AppColors.orange.withOpacity(0.1) : AppColors.bgCardNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _reminderEnabled ? AppColors.orange.withOpacity(0.4) : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alarm, color: AppColors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Medication Reminder', style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
                          ),
                          Switch(
                            value: _reminderEnabled,
                            onChanged: (v) => setState(() => _reminderEnabled = v),
                            activeColor: AppColors.orange,
                            activeTrackColor: AppColors.orange.withOpacity(0.3),
                          ),
                        ],
                      ),
                      if (_reminderEnabled) ...[
                        McDivider(margin: const EdgeInsets.symmetric(vertical: 10)),
                        ..._reminderTimes.map((t) => Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(t, style: AppTextStyles.body.copyWith(color: AppColors.orange)),
                                ),
                                const Spacer(),
                                CustomIconButton(
                                  icon: Icons.close,
                                  onTap: () => setState(() => _reminderTimes.remove(t)),
                                  size: 32,
                                  iconColor: AppColors.textMuted,
                                ),
                              ],
                            )),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => setState(() => _reminderTimes.add('12:00 PM')),
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline, color: AppColors.accentTeal, size: 20),
                              const SizedBox(width: 8),
                              Text('Add reminder time', style: AppTextStyles.tealLabel),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                CustomPrimaryButton(
                  text: 'Save Medication',
                  color: AppColors.teal,
                  isLoading: _isLoading,
                  icon: Icons.check,
                  onTap: () async {
                    if (!_validate()) return;
                    setState(() => _isLoading = true);
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isScanning) _buildScanningOverlay(),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isScanning ? null : _showScanSourceSheet,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.teal.withOpacity(0.12),
                AppColors.primary.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.teal.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner_outlined, color: AppColors.teal, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Medication',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.teal, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'OCR auto-fill from strip, box, or prescription',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.teal.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.teal),
                const SizedBox(height: 16),
                Text('Scanning medication…', style: AppTextStyles.heading3.copyWith(color: AppColors.teal)),
                const SizedBox(height: 6),
                Text(
                  'Reading text with on-device OCR',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: AppTextStyles.captionBold.copyWith(color: color, fontSize: 13)),
    );
  }
}
