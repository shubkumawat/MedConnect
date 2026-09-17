import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/healora_logo.dart';
import '../controllers/records_controller.dart';
import '../services/medication_ocr_service.dart';
import 'package:healaura/app/core/Util/app_toast.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? diseaseUuid;
  final Medication? medication;
  final Map<String, dynamic>? initialData;

  /// When true (or diseaseUuid is null): Current Medication flow.
  /// When false with diseaseUuid: Disease Medication flow.
  final bool isCurrentMedication;
  final String? appointmentUuid;

  const AddMedicationScreen({
    super.key,
    this.diseaseUuid,
    this.medication,
    this.initialData,
    this.isCurrentMedication = false,
    this.appointmentUuid,
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
  final _sideEffectInputCtrl = TextEditingController();
  final _allergyInputCtrl = TextEditingController();

  final MedicationOcrService _ocrService = MedicationOcrService();
  final FocusNode _medNameFocus = FocusNode();
  Timer? _searchDebounce;

  /// API format e.g. 1-0-1
  String? _frequency;
  final _customDaysCtrl = TextEditingController();

  /// API with_food values
  String? _withFood;

  /// API dosage_form value
  String? _dosageForm;

  /// API timing array: morning / afternoon / evening / night
  final Set<String> _selectedTimings = {};
  final Set<String> _selectedSideEffects = {};
  final Set<String> _selectedAllergies = {};

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
    {'label': 'Weekly', 'value': 'weekly'},
    {'label': 'Every N days', 'value': 'every_n_days'},
    {'label': 'As needed (SOS)', 'value': 'SOS'},
  ];

  bool get _isCustomDaysFrequency => _frequency == 'every_n_days';

  List<String> get _frequencyLabels =>
      _frequencyOptions.map((e) => e['label']!).toList();

  String? get _frequencyLabel {
    if (_frequency == null) return null;
    if (_frequency!.startsWith('every_') &&
        _frequency!.endsWith('_days') &&
        _frequency != 'every_n_days') {
      return 'Every N days';
    }
    for (final opt in _frequencyOptions) {
      if (opt['value'] == _frequency) return opt['label'];
    }
    return _frequency;
  }

  String? get _frequencyPayload {
    if (_frequency == null) return null;
    if (_frequency == 'every_n_days') {
      final days = int.tryParse(_customDaysCtrl.text.trim());
      if (days == null || days < 1) return null;
      return 'every_${days}_days';
    }
    return _frequency;
  }

  final _timingOptions = const [
    {'value': 'morning', 'label': 'Morning'},
    {'value': 'afternoon', 'label': 'Afternoon'},
    {'value': 'evening', 'label': 'Evening'},
    {'value': 'night', 'label': 'Night'},
  ];

  final _withFoodOptions = const [
    {'value': 'before_food', 'label': 'Before Food'},
    {'value': 'after_food', 'label': 'After Food'},
    {'value': 'with_food', 'label': 'With Food'},
    {'value': 'empty_stomach', 'label': 'Empty Stomach'},
    {'value': 'any', 'label': 'Anytime'},
  ];

  final _dosageFormOptions = const [
    {'value': 'tablet', 'label': 'Tablet'},
    {'value': 'capsule', 'label': 'Capsule'},
    {'value': 'syrup', 'label': 'Syrup'},
    {'value': 'injection', 'label': 'Injection'},
    {'value': 'drops', 'label': 'Drops'},
    {'value': 'inhaler', 'label': 'Inhaler'},
    {'value': 'topical', 'label': 'Topical'},
    {'value': 'patch', 'label': 'Patch'},
  ];

  static const _sideEffectTags = [
    'Nausea',
    'Vomiting',
    'Dizziness',
    'Headache',
    'Drowsiness',
    'Rash',
    'Itching',
    'Diarrhea',
    'Constipation',
    'Upset stomach',
    'Fatigue',
    'Loss of appetite',
  ];

  static const _allergyTags = [
    'Penicillin',
    'Sulfa',
    'Aspirin',
    'Ibuprofen',
    'Latex',
    'Peanuts',
    'Dairy',
    'Dust',
  ];

  List<String> get _dosageFormLabels =>
      _dosageFormOptions.map((e) => e['label']!).toList();

  String? get _dosageFormLabel {
    if (_dosageForm == null) return null;
    for (final opt in _dosageFormOptions) {
      if (opt['value'] == _dosageForm) return opt['label'];
    }
    return _dosageForm;
  }

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
      _dosageForm = _normalizeDosageForm(med.form);
      _withFood = med.withFood;
      if (_withFood != null &&
          !_withFoodOptions.any((e) => e['value'] == _withFood)) {
        _withFood = _mapLegacyWithFood(_withFood!);
      }
      if (med.timingSlots.isNotEmpty) {
        _ingestTimingValues(med.timingSlots);
      } else if (med.timing.isNotEmpty) {
        _ingestTimingValues(med.timing.split(','));
      }
      _selectedSideEffects.addAll(med.sideEffects);
      _selectedAllergies.addAll(med.allergies);
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
      _dosageForm = _normalizeDosageForm(
        initial['dosage_form']?.toString() ?? initial['form']?.toString(),
      );
      _withFood = initial['with_food']?.toString();
      if (_withFood != null &&
          !_withFoodOptions.any((e) => e['value'] == _withFood)) {
        _withFood = _mapLegacyWithFood(_withFood!);
      }
      final timing = initial['timing'];
      if (timing is List) {
        _ingestTimingValues(timing.map((e) => e.toString()));
      } else if (timing != null) {
        _ingestTimingValues(timing.toString().split(','));
      }
      _withFood ??= _mapLegacyWithFood(initial['timing']?.toString() ?? '');
      _selectedSideEffects.addAll(
        _stringListFrom(initial['side_effects'] ?? initial['side_effects_noted']),
      );
      _selectedAllergies.addAll(_stringListFrom(initial['allergies']));
      _instructionsCtrl.text = initial['instructions']?.toString() ?? '';
    }
  }

  List<String> _stringListFrom(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    return s
        .split(RegExp(r'[,|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String? _normalizeDosageForm(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final lower = value.trim().toLowerCase().replaceAll(' ', '_');
    for (final opt in _dosageFormOptions) {
      if (opt['value'] == lower || opt['label']!.toLowerCase() == lower) {
        return opt['value'];
      }
    }
    if (lower.contains('tab')) return 'tablet';
    if (lower.contains('cap')) return 'capsule';
    if (lower.contains('syrup')) return 'syrup';
    if (lower.contains('inj')) return 'injection';
    if (lower.contains('drop')) return 'drops';
    if (lower.contains('inhal')) return 'inhaler';
    if (lower.contains('cream') ||
        lower.contains('ointment') ||
        lower.contains('gel') ||
        lower.contains('topical')) {
      return 'topical';
    }
    if (lower.contains('patch')) return 'patch';
    return null;
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
    final everyDays = RegExp(r'every[_\s-]?(\d+)[_\s-]?days?').firstMatch(lower);
    if (everyDays != null) {
      _customDaysCtrl.text = everyDays.group(1)!;
      return 'every_n_days';
    }
    if (lower.contains('week')) return 'weekly';
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
    if (lower == 'anytime' || lower.contains('any_time') || lower == 'any') {
      return 'any';
    }
    if (lower.contains('before')) return 'before_food';
    if (lower.contains('after')) return 'after_food';
    if (lower.contains('with')) return 'with_food';
    if (lower.contains('empty')) return 'empty_stomach';
    return null;
  }

  /// Keep only morning/afternoon/evening/night; map food-related values to with_food.
  void _ingestTimingValues(Iterable<String> raw) {
    for (final item in raw) {
      final v = item.trim().toLowerCase().replaceAll(' ', '_');
      if (v.isEmpty) continue;
      if (_timingOptions.any((e) => e['value'] == v)) {
        _selectedTimings.add(v);
        continue;
      }
      if (v == 'bedtime') {
        _selectedTimings.add('night');
        continue;
      }
      final food = _mapLegacyWithFood(v);
      if (food != null && _withFood == null) {
        _withFood = food;
      }
    }
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
    _customDaysCtrl.dispose();
    _sideEffectInputCtrl.dispose();
    _allergyInputCtrl.dispose();
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
      _dosageForm ??= _normalizeDosageForm(result.form);
      if (_frequency == null && result.frequency != null) {
        _frequency = _normalizeFrequency(result.frequency!);
      }
      if (result.timing != null) {
        final t = result.timing!.toLowerCase();
        _withFood ??= _mapLegacyWithFood(result.timing!);
        if (t.contains('bedtime') || t.contains('night')) {
          _selectedTimings.add('night');
        } else if (t.contains('morning') || t.contains('breakfast')) {
          _selectedTimings.add('morning');
        } else if (t.contains('afternoon') || t.contains('noon')) {
          _selectedTimings.add('afternoon');
        } else if (t.contains('evening')) {
          _selectedTimings.add('evening');
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
      'dosage_form': _dosageForm,
      'frequency': _frequencyPayload,
      'timing': _selectedTimings.toList(),
      'with_food': _withFood,
      'side_effects': _selectedSideEffects.toList(),
      'allergies': _selectedAllergies.toList(),
      'start_date':
          _startDateCtrl.text.trim().isEmpty ? null : _startDateCtrl.text.trim(),
      'is_ongoing': _isOngoing,
      'instructions': _instructionsCtrl.text.trim(),
      'status': 'active',
    };

    // Disease-linked meds only — never send null disease_uuid on current meds.
    if (!_isCurrentFlow &&
        _diseaseUuid != null &&
        _diseaseUuid!.trim().isNotEmpty) {
      body['disease_uuid'] = _diseaseUuid!.trim();
    }

    if (!_isOngoing && _endDateCtrl.text.trim().isNotEmpty) {
      body['end_date'] = _endDateCtrl.text.trim();
    }

    return body;
  }

  Future<void> _save() async {
    if (_medNameCtrl.text.trim().isEmpty) {
      AppToast.showToast(msg: 'Please enter a medication name.');
      return;
    }
    if (_dosageForm == null || _dosageForm!.isEmpty) {
      AppToast.showToast(msg: 'Please select dosage form.');
      return;
    }
    if (_frequency == null) {
      AppToast.showToast(msg: 'Please select frequency.');
      return;
    }
    if (_isCustomDaysFrequency) {
      final days = int.tryParse(_customDaysCtrl.text.trim());
      if (days == null || days < 1) {
        AppToast.showToast(
          msg: 'Enter how many days between doses (e.g. 3).',
        );
        return;
      }
    }
    if (_withFood == null || _withFood!.isEmpty) {
      AppToast.showToast(msg: 'Please select With Food option.');
      return;
    }

    if (!_isCurrentFlow && (_diseaseUuid == null || _diseaseUuid!.isEmpty)) {
      AppToast.showToast(msg: 'Disease not selected.');
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
        body: body,
        appointmentUuid: widget.appointmentUuid,
      );

      // );
    }

    if (!mounted) return;

    if (success) {
      Get.back();
      AppToast.showToast(
        msg: _isEdit
            ? 'Medication updated successfully'
            : 'Medication added successfully',
      );
    }
    // API error message already shown via FlutterToast in RecordsController.
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
                          McDropdown(
                            hint: 'Dosage Form *',
                            value: _dosageFormLabel,
                            items: _dosageFormLabels,
                            prefixIcon: Icons.medication_liquid_outlined,
                            onChanged: (label) {
                              setState(() {
                                if (label == null) {
                                  _dosageForm = null;
                                  return;
                                }
                                _dosageForm = _dosageFormOptions.firstWhere(
                                    (e) => e['label'] == label)['value'];
                              });
                            },
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
                                if (label == null) {
                                  _frequency = null;
                                  _customDaysCtrl.clear();
                                  return;
                                }
                                _frequency = _frequencyOptions.firstWhere(
                                    (e) => e['label'] == label)['value'];
                                if (!_isCustomDaysFrequency) {
                                  _customDaysCtrl.clear();
                                }
                              });
                            },
                          ),
                          if (_isCustomDaysFrequency) ...[
                            const SizedBox(height: 12),
                            CustomTextField(
                              hint: 'Every how many days? (e.g. 3)',
                              controller: _customDaysCtrl,
                              prefixIcon: Icons.calendar_view_day_rounded,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(3),
                              ],
                            ),
                          ],
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
                                if (label == null) {
                                  _withFood = null;
                                  return;
                                }
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
                        title: 'Reactions & allergies',
                        caption: 'Optional side effects and allergy notes',
                        icon: Icons.warning_amber_rounded,
                        children: [
                          const _FieldLabel('Side Effects Noted'),
                          const SizedBox(height: 8),
                          _MultiTagPicker(
                            presetTags: _sideEffectTags,
                            selected: _selectedSideEffects,
                            inputCtrl: _sideEffectInputCtrl,
                            hint: 'Add side effect',
                            accent: AppColors.orange,
                            onToggle: (tag) {
                              setState(() {
                                if (_selectedSideEffects.contains(tag)) {
                                  _selectedSideEffects.remove(tag);
                                } else {
                                  _selectedSideEffects.add(tag);
                                }
                              });
                            },
                            onAddCustom: (tag) {
                              setState(() => _selectedSideEffects.add(tag));
                            },
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('Allergies'),
                          const SizedBox(height: 8),
                          _MultiTagPicker(
                            presetTags: _allergyTags,
                            selected: _selectedAllergies,
                            inputCtrl: _allergyInputCtrl,
                            hint: 'Add allergy',
                            accent: AppColors.statusRed,
                            onToggle: (tag) {
                              setState(() {
                                if (_selectedAllergies.contains(tag)) {
                                  _selectedAllergies.remove(tag);
                                } else {
                                  _selectedAllergies.add(tag);
                                }
                              });
                            },
                            onAddCustom: (tag) {
                              setState(() => _selectedAllergies.add(tag));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        step: '04',
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
              const HealoraLogo.chip(),
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

class _MultiTagPicker extends StatelessWidget {
  final List<String> presetTags;
  final Set<String> selected;
  final TextEditingController inputCtrl;
  final String hint;
  final Color accent;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onAddCustom;

  const _MultiTagPicker({
    required this.presetTags,
    required this.selected,
    required this.inputCtrl,
    required this.hint,
    required this.accent,
    required this.onToggle,
    required this.onAddCustom,
  });

  void _addFromInput() {
    final tag = inputCtrl.text.trim();
    if (tag.isEmpty) return;
    onAddCustom(tag);
    inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final extras = selected.where((t) => !presetTags.contains(t)).toList();
    final allTags = [...presetTags, ...extras];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTags.map((tag) {
            final sel = selected.contains(tag);
            return GestureDetector(
              onTap: () => onToggle(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? accent.withValues(alpha: 0.14)
                      : const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? accent : const Color(0xFFE3EBE7),
                  ),
                ),
                child: Text(
                  '${sel ? '✓  ' : '+  '}$tag',
                  style: TextStyle(
                    color: sel ? accent : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                hint: hint,
                controller: inputCtrl,
                prefixIcon: Icons.add_circle_outline,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _addFromInput,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
