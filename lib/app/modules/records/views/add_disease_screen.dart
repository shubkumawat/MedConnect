import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/healora_logo.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../data/models/disease_response_model.dart';
import '../controllers/records_controller.dart';
import 'package:intl/intl.dart';

class AddDiseaseScreen extends StatefulWidget {
  final DiseaseResult? disease;
  const AddDiseaseScreen({super.key, this.disease});

  @override
  State<AddDiseaseScreen> createState() => _AddDiseaseScreenState();
}

class _AddDiseaseScreenState extends State<AddDiseaseScreen> {
  final RecordsController controller = Get.find<RecordsController>();

  final _diseaseNameCtrl = TextEditingController();
  final _icdCodeCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _diagnosedDateCtrl = TextEditingController();
  final _recoveredDateCtrl = TextEditingController();
  final _followUpDateCtrl = TextEditingController();
  final _admittedDateCtrl = TextEditingController();
  final _dischargedDateCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  String? _conditionType;
  String _status = 'Active';
  String _hereditaryStatus = 'NA';
  final Set<String> _selectedBodyParts = {};

  double _severity = 2;
  bool _isHospitalized = false;

  final List<String> _types = [
    'Chronic',
    'Acute',
    'Surgical',
    'Genetic',
    'Infectious',
    'Allergy',
    'Injury',
    'Mental Health',
    'Other'
  ];

  final List<String> _statuses = [
    'Active',
    'Under Monitoring',
    'Resolved',
    'In Remission'
  ];

  final List<String> _bodyParts = [
    'Head',
    'Chest',
    'Abdomen',
    'Back',
    'Arms',
    'Legs',
    'Whole Body',
    'Blood',
    'Other'
  ];

  final List<String> _allSymptoms = [
    'Fever',
    'Pain',
    'Nausea',
    'Fatigue',
    'Cough',
    'Swelling',
    'Dizziness'
  ];
  final List<String> _selectedSymptoms = [];

  String get _severityLabel {
    if (_severity == 1) return 'Mild';
    if (_severity == 2) return 'Moderate';
    return 'Severe';
  }

  Color get _severityColor {
    if (_severity == 1) return AppColors.green;
    if (_severity == 2) return AppColors.orange;
    return AppColors.statusRed;
  }

  bool get _isEdit => widget.disease != null;

  @override
  void initState() {
    super.initState();
    if (widget.disease != null) {
      _diseaseNameCtrl.text = widget.disease!.name ?? '';
      _icdCodeCtrl.text = widget.disease!.icdCode ?? '';
      _notesCtrl.text = widget.disease!.notes ?? '';
      _diagnosedDateCtrl.text = widget.disease!.diagnosedOn ?? '';
      _recoveredDateCtrl.text = widget.disease!.recoveredOn ?? '';
      _followUpDateCtrl.text = widget.disease!.nextFollowUpOn ?? '';
      _admittedDateCtrl.text = widget.disease!.admittedOn ?? '';
      _dischargedDateCtrl.text = widget.disease!.dischargedOn ?? '';
      _categoryCtrl.text = widget.disease!.category ?? '';
      _isHospitalized = widget.disease!.hospitalizationRequired ?? false;
    }
  }

  @override
  void dispose() {
    _diseaseNameCtrl.dispose();
    _icdCodeCtrl.dispose();
    _doctorCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    _diagnosedDateCtrl.dispose();
    _recoveredDateCtrl.dispose();
    _followUpDateCtrl.dispose();
    _admittedDateCtrl.dispose();
    _dischargedDateCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  bool _initialsSet = false;

  void _setInitialValuesFromMeta() {
    if (_initialsSet || widget.disease == null) return;

    if (controller.conditionTypes.isNotEmpty && _conditionType == null) {
      final type = controller.conditionTypes.firstWhere(
        (e) => e['value'] == widget.disease!.conditionType,
        orElse: () => {},
      );
      if (type.isNotEmpty) _conditionType = type['label'];
    }

    if (controller.statuses.isNotEmpty && widget.disease!.status != null) {
      final status = controller.statuses.firstWhere(
        (e) => e['value'] == widget.disease!.status,
        orElse: () => {},
      );
      if (status.isNotEmpty) _status = status['label']!;
    }

    if (controller.hereditaryOptions.isNotEmpty &&
        widget.disease!.hereditary != null) {
      final hereditary = controller.hereditaryOptions.firstWhere(
        (e) => e['value'] == widget.disease!.hereditary,
        orElse: () => {},
      );
      if (hereditary.isNotEmpty) {
        final label = hereditary['label']!;
        _hereditaryStatus =
            label.toLowerCase() == 'unknown' ? 'NA' : label;
      }
    }

    if (controller.bodyPartsOptions.isNotEmpty &&
        widget.disease!.bodyParts != null &&
        widget.disease!.bodyParts!.isNotEmpty) {
      for (final raw in widget.disease!.bodyParts!) {
        final part = controller.bodyPartsOptions.firstWhere(
          (e) => e['value'] == raw || e['label'] == raw,
          orElse: () => {},
        );
        if (part.isNotEmpty) {
          _selectedBodyParts.add(part['label']!);
        } else if (raw.trim().isNotEmpty) {
          _selectedBodyParts.add(raw);
        }
      }
    }

    if (widget.disease!.severity != null) {
      if (widget.disease!.severity == 'mild') {
        _severity = 1;
      } else if (widget.disease!.severity == 'moderate') {
        _severity = 2;
      } else if (widget.disease!.severity == 'severe') {
        _severity = 3;
      }
    }

    _initialsSet = true;
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController ctrl, {
    DateTime? initialDate,
    DateTime? firstDate,
    bool isPastOnly = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: isPastOnly ? DateTime.now() : DateTime(2100),
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
        ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_diseaseNameCtrl.text.isEmpty ||
        _conditionType == null ||
        _diagnosedDateCtrl.text.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Please fill all required fields (*)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.statusRed,
        colorText: Colors.white,
      );
      return;
    }

    final selectedType = controller.conditionTypes.firstWhere(
      (e) => e['label'] == _conditionType,
      orElse: () => {'value': _conditionType!.toLowerCase()},
    )['value'];
    final selectedStatus = (controller.statuses.isEmpty
            ? [
                {'label': _status, 'value': _status.toLowerCase()}
              ]
            : controller.statuses)
        .firstWhere(
      (e) => e['label'] == _status,
      orElse: () => {'value': _status.toLowerCase()},
    )['value'];
    final selectedHereditary = (controller.hereditaryOptions.isEmpty
            ? [
                {
                  'label': _hereditaryStatus,
                  'value': _hereditaryStatus.toLowerCase() == 'na'
                      ? 'unknown'
                      : _hereditaryStatus.toLowerCase(),
                }
              ]
            : controller.hereditaryOptions)
        .firstWhere(
      (e) {
        final label = (e['label'] ?? '').toLowerCase();
        if (_hereditaryStatus.toLowerCase() == 'na') {
          return label == 'na' || label == 'unknown';
        }
        return e['label'] == _hereditaryStatus;
      },
      orElse: () => {
        'value': _hereditaryStatus.toLowerCase() == 'na'
            ? 'unknown'
            : _hereditaryStatus.toLowerCase(),
      },
    )['value'];
    final selectedBodyParts = _selectedBodyParts.map((label) {
      return controller.bodyPartsOptions.firstWhere(
        (e) => e['label'] == label,
        orElse: () => {'value': label.toLowerCase().replaceAll(' ', '_')},
      )['value']!;
    }).toList();

    final bool success;
    if (widget.disease == null) {
      success = await controller.addDisease(
        name: _diseaseNameCtrl.text,
        icdCode: _icdCodeCtrl.text,
        conditionType: selectedType!,
        status: selectedStatus!,
        severity: _severityLabel.toLowerCase(),
        diagnosedOn: _diagnosedDateCtrl.text,
        recoveredOn:
            _recoveredDateCtrl.text.isNotEmpty ? _recoveredDateCtrl.text : null,
        bodyParts: selectedBodyParts,
        hereditary: selectedHereditary!,
        nextFollowUpOn:
            _followUpDateCtrl.text.isNotEmpty ? _followUpDateCtrl.text : null,
        hospitalizationRequired: _isHospitalized,
        admittedOn:
            _admittedDateCtrl.text.isNotEmpty ? _admittedDateCtrl.text : null,
        dischargedOn: _dischargedDateCtrl.text.isNotEmpty
            ? _dischargedDateCtrl.text
            : null,
        notes: _notesCtrl.text,
        category: _categoryCtrl.text,
      );
    } else {
      success = await controller.updateDisease(
        uuid: widget.disease!.uuid!,
        name: _diseaseNameCtrl.text,
        icdCode: _icdCodeCtrl.text,
        conditionType: selectedType!,
        status: selectedStatus!,
        severity: _severityLabel.toLowerCase(),
        diagnosedOn: _diagnosedDateCtrl.text,
        recoveredOn:
            _recoveredDateCtrl.text.isNotEmpty ? _recoveredDateCtrl.text : null,
        bodyParts: selectedBodyParts,
        hereditary: selectedHereditary!,
        nextFollowUpOn:
            _followUpDateCtrl.text.isNotEmpty ? _followUpDateCtrl.text : null,
        hospitalizationRequired: _isHospitalized,
        admittedOn:
            _admittedDateCtrl.text.isNotEmpty ? _admittedDateCtrl.text : null,
        dischargedOn: _dischargedDateCtrl.text.isNotEmpty
            ? _dischargedDateCtrl.text
            : null,
        notes: _notesCtrl.text,
        category: _categoryCtrl.text,
      );
    }

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        _isEdit ? 'Condition updated successfully' : 'Condition added successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.teal,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to process request',
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

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Obx(() {
        _setInitialValuesFromMeta();
        final types = controller.conditionTypes.isNotEmpty
            ? controller.conditionTypes.map((e) => e['label']!).toList()
            : _types;
        final statusList = controller.statuses.isNotEmpty
            ? controller.statuses.toList()
            : <Map<String, String>>[];
        final bodyParts = controller.bodyPartsOptions.isNotEmpty
            ? controller.bodyPartsOptions.map((e) => e['label']!).toList()
            : _bodyParts;
        final hereditaryList = controller.hereditaryOptions.isNotEmpty
            ? controller.hereditaryOptions.toList()
            : <Map<String, String>>[];

        return Column(
          children: [
            _Header(
              topPad: top,
              isEdit: _isEdit,
              onBack: () => Get.back(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  children: [
                    _IntroCard(isEdit: _isEdit),
                    const SizedBox(height: 14),
                    _SectionCard(
                      step: '01',
                      title: 'Condition basics',
                      caption: 'Required clinical identity',
                      icon: Icons.monitor_heart_outlined,
                      children: [
                        CustomTextField(
                          hint: 'Disease / Condition Name *',
                          controller: _diseaseNameCtrl,
                          prefixIcon: Icons.sick_outlined,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'ICD / Diagnosis Code (optional)',
                          controller: _icdCodeCtrl,
                          prefixIcon: Icons.qr_code_2_outlined,
                        ),
                        const SizedBox(height: 12),
                        McDropdown<String>(
                          hint: 'Condition Type *',
                          value: _conditionType,
                          items: types,
                          onChanged: (v) => setState(() => _conditionType = v),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Current status *'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (statusList.isEmpty
                                  ? _statuses
                                      .map((e) => {
                                            'label': e,
                                            'value': e.toLowerCase()
                                          })
                                      .toList()
                                  : statusList)
                              .map((s) {
                            final isSelected = _status == s['label'];
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _status = s['label']!),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.tealDark
                                      : const Color(0xFFF3F7F5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.tealDark
                                        : const Color(0xFFE3EBE7),
                                  ),
                                ),
                                child: Text(
                                  s['label']!,
                                  style: TextStyle(
                                    color: isSelected
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
                        const SizedBox(height: 14),
                        CustomTextField(
                          hint: 'Diagnosed Date *',
                          controller: _diagnosedDateCtrl,
                          prefixIcon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: () => _selectDate(
                            context,
                            _diagnosedDateCtrl,
                            isPastOnly: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      step: '02',
                      title: 'Clinical details',
                      caption: 'Severity, care team & notes',
                      icon: Icons.medical_information_outlined,
                      children: [
                        CustomTextField(
                          hint: 'Attending Doctor',
                          controller: _doctorCtrl,
                          prefixIcon: Icons.person_search_outlined,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'Hospital / Clinic',
                          controller: _hospitalCtrl,
                          prefixIcon: Icons.local_hospital_outlined,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'Category / Specialty',
                          controller: _categoryCtrl,
                          prefixIcon: Icons.category_outlined,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const _FieldLabel('Severity'),
                            const Spacer(),
                            StatusBadge(
                                label: _severityLabel, color: _severityColor),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _severity,
                            min: 1,
                            max: 3,
                            divisions: 2,
                            activeColor: _severityColor,
                            inactiveColor: const Color(0xFFE3EBE7),
                            onChanged: (v) => setState(() => _severity = v),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const _FieldLabel('Symptoms at diagnosis'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSymptoms.map((s) {
                            final sel = _selectedSymptoms.contains(s);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  sel
                                      ? _selectedSymptoms.remove(s)
                                      : _selectedSymptoms.add(s);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.teal.withValues(alpha: 0.12)
                                      : const Color(0xFFF3F7F5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.teal
                                            .withValues(alpha: 0.45)
                                        : const Color(0xFFE3EBE7),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: sel
                                        ? AppColors.tealDark
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Body Part / Affected Area'),
                        const SizedBox(height: 6),
                        Text(
                          'Select one or more areas',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textGray),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: bodyParts.map((part) {
                            final selected = _selectedBodyParts.contains(part);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedBodyParts.remove(part);
                                  } else {
                                    _selectedBodyParts.add(part);
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
                                  '${selected ? '✓  ' : ''}$part',
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
                        CustomTextField(
                          hint: "Notes / Doctor's Advice",
                          controller: _notesCtrl,
                          prefixIcon: Icons.note_alt_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'Next Follow-up Date',
                          controller: _followUpDateCtrl,
                          prefixIcon: Icons.event_repeat,
                          readOnly: true,
                          onTap: () => _selectDate(
                            context,
                            _followUpDateCtrl,
                            firstDate: DateTime.now(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Hereditary?'),
                        const SizedBox(height: 8),
                        Row(
                          children: (hereditaryList.isEmpty
                                  ? ['Yes', 'No', 'NA']
                                      .map((e) => {
                                            'label': e,
                                            'value': e.toLowerCase() == 'na'
                                                ? 'unknown'
                                                : e.toLowerCase(),
                                          })
                                      .toList()
                                  : hereditaryList)
                              .map((item) {
                            final raw = item['label']!;
                            final val = raw.toLowerCase() == 'unknown'
                                ? 'NA'
                                : raw;
                            final isSelected = _hereditaryStatus == val;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _hereditaryStatus = val),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.tealDark
                                        : const Color(0xFFF3F7F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.tealDark
                                          : const Color(0xFFE3EBE7),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      val,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textMuted,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      step: '03',
                      title: 'Hospitalization',
                      caption: 'Admission & discharge (if any)',
                      icon: Icons.local_hotel_outlined,
                      children: [
                        _ToggleCard(
                          label: 'Hospitalization required?',
                          value: _isHospitalized,
                          onChanged: (v) =>
                              setState(() => _isHospitalized = v),
                          color: AppColors.orange,
                        ),
                        if (_isHospitalized) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  hint: 'Admission',
                                  controller: _admittedDateCtrl,
                                  prefixIcon: Icons.login_rounded,
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                    context,
                                    _admittedDateCtrl,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  hint: 'Discharge',
                                  controller: _dischargedDateCtrl,
                                  prefixIcon: Icons.logout_rounded,
                                  readOnly: true,
                                  onTap: () => _selectDate(
                                    context,
                                    _dischargedDateCtrl,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE3EBE7)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _submit,
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
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Condition' : 'Save Condition',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  final bool isEdit;
  final VoidCallback onBack;

  const _Header({
    required this.topPad,
    required this.isEdit,
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
              const HealoraLogo.chip(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Condition' : 'Add Condition',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Structured clinical record entry',
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                _ChipStep(active: true, label: 'Basics'),
                _dot(),
                _ChipStep(active: true, label: 'Clinical'),
                _dot(),
                _ChipStep(active: true, label: 'Hospital'),
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
  final bool active;
  final String label;
  const _ChipStep({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: active ? 0.95 : 0.55),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final bool isEdit;
  const _IntroCard({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            child: const Icon(Icons.health_and_safety_outlined,
                color: AppColors.tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Update health condition' : 'New health condition',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Capture diagnosis details in a clinic-ready format.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                      ),
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
  final Color color;

  const _ToggleCard({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.08) : const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.35)
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
            activeTrackColor: color.withValues(alpha: 0.45),
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}
