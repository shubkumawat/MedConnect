import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/records_controller.dart';
import '../services/medication_ocr_service.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? diseaseUuid;
  final Medication? medication;
  final Map<String, dynamic>? initialData;

  /// When true (or diseaseUuid is null): Current Medication flow.
  /// When false with diseaseUuid: Disease Medication flow.
  final bool isCurrentMedication;

  const AddMedicationScreen({
    super.key,
    this.diseaseUuid,
    this.medication,
    this.initialData,
    this.isCurrentMedication = false,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final RecordsController controller = Get.find<RecordsController>();

  final _medNameCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  final MedicationOcrService _ocrService = MedicationOcrService();
  final FocusNode _medNameFocus = FocusNode();
  Timer? _searchDebounce;

  /// API  format e.g. 1-0-1
  String? _frequency; // stores API value e.g. 1-0-0

  /// API with_food values
  String? _withFood;

  /// API timing array: morning / afternoon / evening / night
  final Set<String> _selectedTimings = {};

  bool _isOngoing = true;
  bool _isScanning = false;
  bool _showSearchResults = false;

  /// UI label → API frequency value (sent in body as 1-0-0 etc.)
  static const _frequencyOptions = [
    {'label': 'Once daily', 'value': '1-0-0'},
    {'label': 'Twice daily', 'value': '1-0-1'},
    {'label': 'Three times daily', 'value': '1-1-1'},
    {'label': 'Four times daily', 'value': '1-1-1-1'},
    {'label': 'Every 6 hours', 'value': 'every_6_hours'},
    {'label': 'Every 8 hours', 'value': 'every_8_hours'},
    {'label': 'As needed (SOS)', 'value': 'SOS'},
  ];

  List<String> get _frequencyLabels =>
      _frequencyOptions.map((e) => e['label']!).toList();

  String? get _frequencyLabel {
    if (_frequency == null) return null;
    for (final opt in _frequencyOptions) {
      if (opt['value'] == _frequency) return opt['label'];
    }
    return _frequency;
  }

  final _timingOptions = const [
    {'value': 'morning', 'label': 'Morning'},
    {'value': 'evening', 'label': 'Evening'},
    {'value': 'before_food', 'label': 'Before Food'},
    {'value': 'after_food', 'label': 'After Food'},
    {'value': 'with_food', 'label': 'With Food'},
    {'value': 'bedtime', 'label': 'Bedtime'},
  ];

  final _withFoodOptions = const [
    {'value': 'before_food', 'label': 'Before Food'},
    {'value': 'after_food', 'label': 'After Food'},
    {'value': 'with_food', 'label': 'With Food'},
    {'value': 'empty_stomach', 'label': 'Empty Stomach'},
  ];

  bool get _isEdit => widget.medication != null;

  /// Current flow: Health Record Medications tab (no disease APIs).
  bool get _isCurrentFlow =>
      widget.isCurrentMedication ||
      (widget.diseaseUuid == null || widget.diseaseUuid!.isEmpty);

  String? get _diseaseUuid => widget.diseaseUuid;

  @override
  void initState() {
    super.initState();
    _prefill();
    _medNameCtrl.addListener(_onMedNameChanged);
    _medNameFocus.addListener(() {
      if (!_medNameFocus.hasFocus) {
        setState(() => _showSearchResults = false);
      }
    });
  }

  void _prefill() {
    final med = widget.medication;
    final initial = widget.initialData;

    if (med != null) {
      _medNameCtrl.text = med.name;
      _strengthCtrl.text = med.strength ?? '';
      _dosageCtrl.text = med.dosage ?? '';
      _frequency = med.frequency.isNotEmpty ? _normalizeFrequency(med.frequency) : null;
      _selectedTimings.addAll(med.timingSlots);
      if (_selectedTimings.isEmpty && med.timing.isNotEmpty) {
        for (final t in med.timing.split(',')) {
          final v = t.trim().toLowerCase().replaceAll(' ', '_');
          if (_timingOptions.any((e) => e['value'] == v)) {
            _selectedTimings.add(v);
          }
        }
      }
      _withFood = med.withFood;
      if (_withFood != null &&
          !_withFoodOptions.any((e) => e['value'] == _withFood)) {
        _withFood = _mapLegacyWithFood(_withFood!);
      }
      _isOngoing = med.isOngoing;
      _instructionsCtrl.text = med.instructions ?? '';
      if (med.startDate != null && med.startDate!.isNotEmpty) {
        _startDateCtrl.text = med.startDate!;
      }
      if (med.endDate != null && med.endDate!.isNotEmpty) {
        _endDateCtrl.text = med.endDate!;
      }
    } else if (initial != null) {
      _medNameCtrl.text = initial['name']?.toString() ?? '';
      _strengthCtrl.text =
          initial['strength']?.toString() ?? initial['dosage']?.toString() ?? '';
      _dosageCtrl.text = initial['dosage']?.toString() ?? '';
      _frequency = _normalizeFrequency(initial['frequency']?.toString() ?? '');
      final timing = initial['timing'];
      if (timing is List) {
        _selectedTimings.addAll(timing.map((e) => e.toString()));
      }
      _withFood = initial['with_food']?.toString() ??
          _mapLegacyWithFood(initial['timing']?.toString() ?? '');
      _instructionsCtrl.text = initial['instructions']?.toString() ?? '';
    }
  }

  /// Normalize any frequency (API code or label) → API value.
  String? _normalizeFrequency(String value) {
    if (value.isEmpty) return null;
    for (final opt in _frequencyOptions) {
      if (opt['value'] == value || opt['label']!.toLowerCase() == value.toLowerCase()) {
        return opt['value'];
      }
    }
    final lower = value.toLowerCase();
    if (lower.contains('sos') || lower.contains('as needed') || lower.contains('prn')) {
      return 'SOS';
    }
    if (lower.contains('every 6') || lower.contains('every_6')) return 'every_6_hours';
    if (lower.contains('every 8') || lower.contains('every_8')) return 'every_8_hours';
    if (lower.contains('four') || lower.contains('4x') || lower.contains('qid') || value == '1-1-1-1') {
      return '1-1-1-1';
    }
    if (lower.contains('three') || lower.contains('3x') || lower.contains('tid') || lower.contains('thrice') || value == '1-1-1') {
      return '1-1-1';
    }
    if (lower.contains('twice') || lower.contains('2x') || lower.contains('bid') || value == '1-0-1' || value == '1-1-0' || value == '0-1-1') {
      return '1-0-1';
    }
    if (lower.contains('once') || lower.contains('od') || value == '1-0-0' || value == '0-1-0' || value == '0-0-1') {
      return '1-0-0';
    }
    return null;
  }

  String? _mapLegacyWithFood(String value) {
    if (value.isEmpty) return null;
    final lower = value.toLowerCase().replaceAll(' ', '_');
    if (_withFoodOptions.any((e) => e['value'] == lower)) return lower;
    if (lower.contains('before')) return 'before_food';
    if (lower.contains('after')) return 'after_food';
    if (lower.contains('with')) return 'with_food';
    if (lower.contains('empty')) return 'empty_stomach';
    if (lower.contains('bedtime') || lower.contains('night')) return 'after_food';
    return null;
  }

  void _onMedNameChanged() {
    _searchDebounce?.cancel();
    final q = _medNameCtrl.text.trim();
    if (q.length < 2) {
      controller.medicineSearchResults.clear();
      if (_showSearchResults) setState(() => _showSearchResults = false);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      await controller.searchMedicines(q);
      if (mounted && _medNameFocus.hasFocus) {
        setState(() => _showSearchResults = controller.medicineSearchResults.isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _medNameCtrl.removeListener(_onMedNameChanged);
    _medNameCtrl.dispose();
    _strengthCtrl.dispose();
    _dosageCtrl.dispose();
    _instructionsCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _medNameFocus.dispose();
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
        final formatted =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        if (isStart) {
          _startDateCtrl.text = formatted;
        } else {
          _endDateCtrl.text = formatted;
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
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined, color: AppColors.teal),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _runScan(MedicationScanSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.orange),
                  title: const Text('Choose from Gallery'),
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
      );
      return;
    }

    _applyOcrResult(outcome.result!);
    Get.snackbar(
      'Scan Complete',
      'Detected fields were filled. Review before saving.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.teal,
      colorText: Colors.white,
    );
  }

  void _applyOcrResult(MedicationOcrResult result) {
    setState(() {
      if (_medNameCtrl.text.trim().isEmpty && (result.name?.isNotEmpty ?? false)) {
        _medNameCtrl.text = result.name!;
      }
      if (_strengthCtrl.text.trim().isEmpty &&
          (result.dosage?.isNotEmpty ?? false)) {
        final unit = result.dosageUnit ?? 'mg';
        _strengthCtrl.text = '${result.dosage}$unit';
      }
      if (_dosageCtrl.text.trim().isEmpty && (result.form?.isNotEmpty ?? false)) {
        _dosageCtrl.text = '1 ${result.form!.toLowerCase()}';
      }
      if (_frequency == null && result.frequency != null) {
        _frequency = _normalizeFrequency(result.frequency!);
      }
      if (_withFood == null && result.timing != null) {
        _withFood = _mapLegacyWithFood(result.timing!);
        if (result.timing!.toLowerCase().contains('bedtime') ||
            result.timing!.toLowerCase().contains('night')) {
          _selectedTimings.add('night');
        }
      }
      if (_instructionsCtrl.text.trim().isEmpty &&
          (result.instructions?.isNotEmpty ?? false)) {
        _instructionsCtrl.text = result.instructions!;
      }
    });
  }

  void _applySearchResult(Map<String, dynamic> item) {
    setState(() {
      _medNameCtrl.text =
          item['name']?.toString() ?? item['brand_name']?.toString() ?? _medNameCtrl.text;
      final strength = item['strength']?.toString() ?? item['dosage']?.toString();
      if (strength != null && strength.isNotEmpty && _strengthCtrl.text.isEmpty) {
        _strengthCtrl.text = strength;
      }
      _showSearchResults = false;
    });
    _medNameFocus.unfocus();
  }

  /// Matches API body from medication curl sample.
  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      "name": _medNameCtrl.text.trim(),
      "strength": _strengthCtrl.text.trim(),
      "dosage": _dosageCtrl.text.trim(),
      "frequency": _frequency,
      "timing": _selectedTimings.toList(),
      "with_food": _withFood,
      "start_date":
          _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
      "is_ongoing": _isOngoing,
      "instructions": _instructionsCtrl.text.trim(),
      "status": "active",
    };

    if (!_isOngoing && _endDateCtrl.text.trim().isEmpty == false) {
      body["end_date"] = _endDateCtrl.text.trim();
    }

    // Disease-scoped only: attach disease context fields
    if (!_isCurrentFlow) {
      final disease = controller.selectedDisease.value;
      if (disease?.conditionType != null && disease!.conditionType!.isNotEmpty) {
        body["condition_type"] = disease.conditionType;
      }
      if (disease?.diagnosedOn != null && disease!.diagnosedOn!.isNotEmpty) {
        body["diagnosed_on"] = disease.diagnosedOn;
      }
    }

    return body;
  }

  Future<void> _save() async {
    if (_medNameCtrl.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter a medication name.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }
    if (_frequency == null) {
      Get.snackbar('Required', 'Please select frequency.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }

    if (!_isCurrentFlow && (_diseaseUuid == null || _diseaseUuid!.isEmpty)) {
      Get.snackbar('Error', 'Disease not selected.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    final body = _buildBody();
    bool success;

    if (_isEdit) {
      success = await controller.updateMedication(
        medicationUuid: widget.medication!.id,
        body: body,
        diseaseUuid: _isCurrentFlow ? null : _diseaseUuid,
        isCurrentMedication: _isCurrentFlow,
      );
    } else if (_isCurrentFlow) {
      success = await controller.addCurrentMedication(body);
    } else {
      success = await controller.addDiseaseMedication(
        diseaseUuid: _diseaseUuid!,
        body: body,
      );
    }

    if (!mounted) return;

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        _isEdit ? 'Medication updated successfully' : 'Medication added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('Error', 'Failed to save medication. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final withFoodLabels = _withFoodOptions.map((e) => e['label']!).toList();
    String? withFoodLabel;
    if (_withFood != null) {
      withFoodLabel = _withFoodOptions
          .firstWhere((e) => e['value'] == _withFood, orElse: () => {'label': _withFood!})['label'];
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: _isEdit
            ? '✏️ Edit Medication'
            : (_isCurrentFlow ? '💊 Add Current Medication' : '💊 Add Medication'),
        showBack: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScanButton(),
                const SizedBox(height: 20),
                _SectionBadge('Drug Info', AppColors.teal),
                const SizedBox(height: 14),
                CustomTextField(
                  hint: 'Medication Name',
                  controller: _medNameCtrl,
                  focusNode: _medNameFocus,
                  prefixIcon: Icons.medication_outlined,
                ),
                Obx(() {
                  final results = controller.medicineSearchResults.toList();
                  if (!_showSearchResults || results.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length.clamp(0, 8),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = results[i];
                        final name = item['name']?.toString() ??
                            item['brand_name']?.toString() ??
                            'Medicine';
                        return ListTile(
                          dense: true,
                          title: Text(name, style: AppTextStyles.bodyBold.copyWith(fontSize: 13)),
                          onTap: () => _applySearchResult(item),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 12),
                CustomTextField(
                  hint: 'Strength (e.g. 650mg)',
                  controller: _strengthCtrl,
                  prefixIcon: Icons.science_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  hint: 'Dosage (e.g. 1 tablet)',
                  controller: _dosageCtrl,
                  prefixIcon: Icons.format_list_numbered,
                ),
                const SizedBox(height: 12),
                McDropdown(
                  hint: 'Frequency',
                  value: _frequencyLabel,
                  items: _frequencyLabels,
                  onChanged: (label) {
                    setState(() {
                      _frequency = _frequencyOptions
                          .firstWhere((e) => e['label'] == label)['value'];
                    });
                  },
                ),
                const SizedBox(height: 14),
                Text('Timing', style: AppTextStyles.captionBold.copyWith(color: AppColors.teal)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timingOptions.map((opt) {
                    final value = opt['value']!;
                    final selected = _selectedTimings.contains(value);
                    return FilterChip(
                      label: Text(opt['label']!),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTimings.add(value);
                          } else {
                            _selectedTimings.remove(value);
                          }
                        });
                      },
                      selectedColor: AppColors.teal.withOpacity(0.2),
                      checkmarkColor: AppColors.teal,
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: selected ? AppColors.teal : AppColors.textMuted,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.teal : AppColors.border,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                McDropdown(
                  hint: 'With Food',
                  value: withFoodLabel,
                  items: withFoodLabels,
                  onChanged: (label) {
                    setState(() {
                      _withFood = _withFoodOptions
                          .firstWhere((e) => e['label'] == label)['value'];
                    });
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  hint: 'Instructions (optional)',
                  controller: _instructionsCtrl,
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                McDivider(),
                _SectionBadge('Schedule', AppColors.primary),
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
                              child: Center(
                                child: Text('Ongoing',
                                    style: AppTextStyles.tealLabel.copyWith(fontSize: 14)),
                              ),
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
                const SizedBox(height: 32),
                Obx(() => CustomPrimaryButton(
                      text: _isEdit ? 'Update Medication' : 'Save Medication',
                      color: AppColors.teal,
                      isLoading: controller.isLoading.value,
                      icon: Icons.check,
                      onTap: _save,
                    )),
                const SizedBox(height: 30),
              ],
            ),
          ),
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Container(
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
                        Text('Scanning medication…',
                            style: AppTextStyles.heading3.copyWith(color: AppColors.teal)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
            color: AppColors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.teal.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.document_scanner_outlined, color: AppColors.teal, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Medication',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.teal, fontSize: 15)),
                    Text('OCR auto-fill from strip, box, or prescription',
                        style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.teal),
            ],
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
