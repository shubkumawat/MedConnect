import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
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

  /// API format e.g. 1-0-1
  String? _frequency;

  /// API with_food values
  String? _withFood;

  /// API timing array: morning / afternoon / evening / night
  final Set<String> _selectedTimings = {};

  bool _isOngoing = true;
  bool _isScanning = false;
  bool _showSearchResults = false;

  /// UI label → API frequency value
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
      _frequency =
          med.frequency.isNotEmpty ? _normalizeFrequency(med.frequency) : null;
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

  String? _normalizeFrequency(String value) {
    if (value.isEmpty) return null;
    for (final opt in _frequencyOptions) {
      if (opt['value'] == value ||
          opt['label']!.toLowerCase() == value.toLowerCase()) {
        return opt['value'];
      }
    }
    final lower = value.toLowerCase();
    if (lower.contains('sos') ||
        lower.contains('as needed') ||
        lower.contains('prn')) {
      return 'SOS';
    }
    if (lower.contains('every 6') || lower.contains('every_6')) {
      return 'every_6_hours';
    }
    if (lower.contains('every 8') || lower.contains('every_8')) {
      return 'every_8_hours';
    }
    if (lower.contains('four') ||
        lower.contains('4x') ||
        lower.contains('qid') ||
        value == '1-1-1-1') {
      return '1-1-1-1';
    }
    if (lower.contains('three') ||
        lower.contains('3x') ||
        lower.contains('tid') ||
        lower.contains('thrice') ||
        value == '1-1-1') {
      return '1-1-1';
    }
    if (lower.contains('twice') ||
        lower.contains('2x') ||
        lower.contains('bid') ||
        value == '1-0-1' ||
        value == '1-1-0' ||
        value == '0-1-1') {
      return '1-0-1';
    }
    if (lower.contains('once') ||
        lower.contains('od') ||
        value == '1-0-0' ||
        value == '0-1-0' ||
        value == '0-0-1') {
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
    if (lower.contains('bedtime') || lower.contains('night')) {
      return 'after_food';
    }
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
        setState(() =>
            _showSearchResults = controller.medicineSearchResults.isNotEmpty);
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
              primary: AppColors.tealDark,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).padding.bottom;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF2F6F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 12, 14, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A5C45),
                        Color(0xFF147A68),
                        Color(0xFF1B9E8E)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.document_scanner_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scan medication',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'OCR auto-fill from strip, box or prescription',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.78),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx),
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(Icons.close_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + bottom),
                  child: Column(
                    children: [
                      _SheetTile(
                        step: '01',
                        icon: Icons.photo_camera_outlined,
                        label: 'Take photo',
                        subtitle: 'Use camera to capture the medicine label',
                        color: AppColors.tealDark,
                        onTap: () {
                          Navigator.pop(ctx);
                          _runScan(MedicationScanSource.camera);
                        },
                      ),
                      const SizedBox(height: 10),
                      _SheetTile(
                        step: '02',
                        icon: Icons.photo_library_outlined,
                        label: 'Choose from gallery',
                        subtitle: 'Pick an existing image from your phone',
                        color: AppColors.orange,
                        onTap: () {
                          Navigator.pop(ctx);
                          _runScan(MedicationScanSource.gallery);
                        },
                      ),
                    ],
                  ),
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
      if (_medNameCtrl.text.trim().isEmpty &&
          (result.name?.isNotEmpty ?? false)) {
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
      _medNameCtrl.text = item['name']?.toString() ??
          item['brand_name']?.toString() ??
          _medNameCtrl.text;
      final strength =
          item['strength']?.toString() ?? item['dosage']?.toString();
      if (strength != null &&
          strength.isNotEmpty &&
          _strengthCtrl.text.isEmpty) {
        _strengthCtrl.text = strength;
      }
      _showSearchResults = false;
    });
    _medNameFocus.unfocus();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'name': _medNameCtrl.text.trim(),
      'strength': _strengthCtrl.text.trim(),
      'dosage': _dosageCtrl.text.trim(),
      'frequency': _frequency,
      'timing': _selectedTimings.toList(),
      'with_food': _withFood,
      'start_date':
          _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
      'is_ongoing': _isOngoing,
      'instructions': _instructionsCtrl.text.trim(),
      'status': 'active',
    };

    if (!_isOngoing && _endDateCtrl.text.trim().isNotEmpty) {
      body['end_date'] = _endDateCtrl.text.trim();
    }

    if (!_isCurrentFlow) {
      final disease = controller.selectedDisease.value;
      if (disease?.conditionType != null &&
          disease!.conditionType!.isNotEmpty) {
        body['condition_type'] = disease.conditionType;
      }
      if (disease?.diagnosedOn != null && disease!.diagnosedOn!.isNotEmpty) {
        body['diagnosed_on'] = disease.diagnosedOn;
      }
    }

    return body;
  }

  Future<void> _save() async {
    if (_medNameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a medication name.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (_frequency == null) {
      Get.snackbar(
        'Required',
        'Please select frequency.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!_isCurrentFlow && (_diseaseUuid == null || _diseaseUuid!.isEmpty)) {
      Get.snackbar(
        'Error',
        'Disease not selected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.statusRed,
        colorText: Colors.white,
      );
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
        _isEdit
            ? 'Medication updated successfully'
            : 'Medication added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.teal,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to save medication. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.statusRed,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    final withFoodLabels = _withFoodOptions.map((e) => e['label']!).toList();
    String? withFoodLabel;
    if (_withFood != null) {
      withFoodLabel = _withFoodOptions.firstWhere(
        (e) => e['value'] == _withFood,
        orElse: () => {'label': _withFood!},
      )['label'];
    }

    final title = _isEdit
        ? 'Edit Medication'
        : (_isCurrentFlow ? 'Add Current Medication' : 'Add Medication');
    final subtitle = _isCurrentFlow
        ? 'Track medicines you take regularly'
        : 'Link medicine to this condition';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Stack(
        children: [
          Column(
            children: [
              _Header(
                topPad: top,
                title: title,
                subtitle: subtitle,
                onBack: () => Get.back(),
                onScan: _isScanning ? null : _showScanSourceSheet,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    children: [
                      _ScanCard(
                        onTap: _isScanning ? null : _showScanSourceSheet,
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        step: '01',
                        title: 'Drug information',
                        caption: 'Name, strength and dosage',
                        icon: Icons.medication_outlined,
                        children: [
                          CustomTextField(
                            hint: 'Medication Name *',
                            controller: _medNameCtrl,
                            focusNode: _medNameFocus,
                            prefixIcon: Icons.medication_outlined,
                          ),
                          Obx(() {
                            final results =
                                controller.medicineSearchResults.toList();
                            if (!_showSearchResults || results.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              constraints: const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFE3EBE7)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.tealDark
                                        .withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: results.length.clamp(0, 8),
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE3EBE7),
                                ),
                                itemBuilder: (_, i) {
                                  final item = results[i];
                                  final name = item['name']?.toString() ??
                                      item['brand_name']?.toString() ??
                                      'Medicine';
                                  return ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F2EE),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.medication_rounded,
                                        size: 18,
                                        color: AppColors.tealDark,
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: AppColors.textDark,
                                      ),
                                    ),
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        step: '02',
                        title: 'Dosage schedule',
                        caption: 'Frequency, timing and food rules',
                        icon: Icons.schedule_outlined,
                        children: [
                          McDropdown(
                            hint: 'Frequency *',
                            value: _frequencyLabel,
                            items: _frequencyLabels,
                            onChanged: (label) {
                              setState(() {
                                _frequency = _frequencyOptions.firstWhere(
                                    (e) => e['label'] == label)['value'];
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Timing'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _timingOptions.map((opt) {
                              final value = opt['value']!;
                              final selected =
                                  _selectedTimings.contains(value);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedTimings.remove(value);
                                    } else {
                                      _selectedTimings.add(value);
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.tealDark
                                        : const Color(0xFFF3F7F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.tealDark
                                          : const Color(0xFFE3EBE7),
                                    ),
                                  ),
                                  child: Text(
                                    opt['label']!,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
                                  ),
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
                                _withFood = _withFoodOptions.firstWhere(
                                    (e) => e['label'] == label)['value'];
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        step: '03',
                        title: 'Duration',
                        caption: 'Start date and ongoing status',
                        icon: Icons.event_available_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  hint: 'Start Date',
                                  controller: _startDateCtrl,
                                  prefixIcon: Icons.calendar_today_outlined,
                                  readOnly: true,
                                  onTap: () => _selectDate(context, true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _isOngoing
                                    ? Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: AppColors.teal
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.teal
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Ongoing',
                                            style: TextStyle(
                                              color: AppColors.tealDark,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                    : CustomTextField(
                                        hint: 'End Date',
                                        controller: _endDateCtrl,
                                        prefixIcon: Icons.event_outlined,
                                        readOnly: true,
                                        onTap: () =>
                                            _selectDate(context, false),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ToggleCard(
                            label: 'Mark as ongoing medication',
                            value: _isOngoing,
                            onChanged: (v) => setState(() => _isOngoing = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
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
                child: Obx(() {
                  final loading = controller.isLoading.value;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.tealDark.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? 'Update Medication'
                                  : 'Save Medication',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ],
          ),
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.teal),
                        const SizedBox(height: 16),
                        Text(
                          'Scanning medication…',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.tealDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
}

// ── UI pieces ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback? onScan;

  const _Header({
    required this.topPad,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 14, 16),
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
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (onScan != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onScan,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.document_scanner_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                _ChipStep('Drug'),
                _dot(),
                _ChipStep('Schedule'),
                _dot(),
                _ChipStep('Duration'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(Icons.circle,
            size: 4, color: Colors.white.withValues(alpha: 0.45)),
      );
}

class _ChipStep extends StatelessWidget {
  final String label;
  const _ChipStep(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _ScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.document_scanner_outlined,
                    color: AppColors.tealDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan medication',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'OCR auto-fill from strip, box or prescription',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.teal.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String step;
  final String title;
  final String caption;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.step,
    required this.title,
    required this.caption,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.tealDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      caption,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  step,
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.captionBold.copyWith(
        color: AppColors.textMuted,
        fontSize: 12.5,
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? AppColors.teal.withValues(alpha: 0.08)
            : const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? AppColors.teal.withValues(alpha: 0.35)
              : const Color(0xFFE3EBE7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.teal.withValues(alpha: 0.45),
            activeThumbColor: AppColors.tealDark,
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final String step;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.step,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealDark.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F7F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            step,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
