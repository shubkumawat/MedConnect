import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
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

  DateTime? _selectedDiagnosedDate;
  DateTime? _selectedRecoveredDate;
  DateTime? _selectedFollowUpDate;
  DateTime? _selectedAdmittedDate;
  DateTime? _selectedDischargedDate;

  String? _conditionType;
  String _status = 'Active'; // Mandatory Pill Select
  String _hereditaryStatus = 'Unknown'; // Yes / No / Unknown
  String? _bodyPart;

  double _severity = 2; // 1=Mild, 2=Moderate, 3=Severe
  bool _isHospitalized = false;

  final List<String> _types = [
    'Chronic', 'Acute', 'Surgical', 'Genetic', 
    'Infectious', 'Allergy', 'Injury', 'Mental Health', 'Other'
  ];
  
  final List<String> _statuses = ['Active', 'Under Monitoring', 'Resolved', 'In Remission'];
  
  final List<String> _bodyParts = ['Head', 'Chest', 'Abdomen', 'Back', 'Arms', 'Legs', 'Whole Body', 'Blood', 'Other'];

  final List<String> _allSymptoms = ['Fever', 'Pain', 'Nausea', 'Fatigue', 'Cough', 'Swelling', 'Dizziness'];
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

  @override
  void initState() {
    super.initState();
    if (widget.disease != null) {
      _diseaseNameCtrl.text = widget.disease!.name ?? "";
      _icdCodeCtrl.text = widget.disease!.icdCode ?? "";
      _notesCtrl.text = widget.disease!.notes ?? "";
      _diagnosedDateCtrl.text = widget.disease!.diagnosedOn ?? "";
      _recoveredDateCtrl.text = widget.disease!.recoveredOn ?? "";
      _followUpDateCtrl.text = widget.disease!.nextFollowUpOn ?? "";
      _admittedDateCtrl.text = widget.disease!.admittedOn ?? "";
      _dischargedDateCtrl.text = widget.disease!.dischargedOn ?? "";
      _categoryCtrl.text = widget.disease!.category ?? "";
      
      _isHospitalized = widget.disease!.hospitalizationRequired ?? false;
    }
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

    if (controller.hereditaryOptions.isNotEmpty && widget.disease!.hereditary != null) {
      final hereditary = controller.hereditaryOptions.firstWhere(
        (e) => e['value'] == widget.disease!.hereditary,
        orElse: () => {},
      );
      if (hereditary.isNotEmpty) _hereditaryStatus = hereditary['label']!;
    }

    if (controller.bodyPartsOptions.isNotEmpty && widget.disease!.bodyParts != null && widget.disease!.bodyParts!.isNotEmpty) {
      final part = controller.bodyPartsOptions.firstWhere(
        (e) => e['value'] == widget.disease!.bodyParts!.first,
        orElse: () => {},
      );
      if (part.isNotEmpty) _bodyPart = part['label'];
    }

    if (widget.disease!.severity != null) {
      if (widget.disease!.severity == 'mild') _severity = 1;
      else if (widget.disease!.severity == 'moderate') _severity = 2;
      else if (widget.disease!.severity == 'severe') _severity = 3;
    }

    _initialsSet = true;
  }

  Future<void> _selectDate(BuildContext context, TextEditingController ctrl, Function(DateTime) onSelected, {DateTime? initialDate, DateTime? firstDate, bool isPastOnly = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: isPastOnly ? DateTime.now() : DateTime(2100),
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
        onSelected(picked);
        ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: widget.disease == null ? 'Add Disease / Condition' : 'Edit Disease',
        showBack: true,
      ),
      body: Obx(() {
        _setInitialValuesFromMeta();
        // Fallback to local lists if meta hasn't loaded yet
        final types = controller.conditionTypes.isNotEmpty 
            ? controller.conditionTypes.map((e) => e['label']!).toList() 
            : _types;
        
        final statusList = controller.statuses.isNotEmpty ? controller.statuses.toList() : [];
        
        final bodyParts = controller.bodyPartsOptions.isNotEmpty 
            ? controller.bodyPartsOptions.map((e) => e['label']!).toList() 
            : _bodyParts;

        final hereditaryList = controller.hereditaryOptions.isNotEmpty ? controller.hereditaryOptions.toList() : [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Core Info Section ─────────────────────────────────────
              const _SectionLabel(label: 'Required Fields', color: AppColors.teal),
              const SizedBox(height: 14),

              CustomTextField(
                hint: 'Disease / Condition Name *',
                controller: _diseaseNameCtrl,
                prefixIcon: Icons.sick_outlined,
              ),
              const SizedBox(height: 12),

              McDropdown<String>(
                hint: 'Condition Type *',
                value: _conditionType,
                items: types,
                onChanged: (v) => setState(() => _conditionType = v),
              ),
              const SizedBox(height: 16),

              Text('Current Status *', style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (statusList.isEmpty 
                    ? _statuses.map((e) => {'label': e, 'value': e.toLowerCase()}).toList() 
                    : statusList).map((s) {
                  final isSelected = _status == s['label'];
                  return ChoiceChip(
                    label: Text(s['label']!),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _status = s['label']!),
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: AppTextStyles.captionBold.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context, _diagnosedDateCtrl, (d) => _selectedDiagnosedDate = d, isPastOnly: true),
                child: AbsorbPointer(
                  child: CustomTextField(
                    hint: 'Diagnosed Date *',
                    controller: _diagnosedDateCtrl,
                    prefixIcon: Icons.calendar_today_outlined,
                    readOnly: true,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const _SectionLabel(label: 'Medical Details', color: AppColors.primary),
              const SizedBox(height: 14),

              CustomTextField(
                hint: 'Attending Doctor Name',
                controller: _doctorCtrl,
                prefixIcon: Icons.person_search_outlined,
              ),
              const SizedBox(height: 12),

              CustomTextField(
                hint: 'Hospital / Clinic Name',
                controller: _hospitalCtrl,
                prefixIcon: Icons.local_hospital_outlined,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  const Text('Severity Level:', style: AppTextStyles.caption),
                  const SizedBox(width: 10),
                  StatusBadge(label: _severityLabel, color: _severityColor),
                ],
              ),
              Slider(
                value: _severity,
                min: 1,
                max: 3,
                divisions: 2,
                activeColor: _severityColor,
                inactiveColor: AppColors.border,
                onChanged: (v) => setState(() => _severity = v),
              ),
              const SizedBox(height: 12),

              Text('Symptoms at Diagnosis', style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSymptoms.map((s) {
                  final sel = _selectedSymptoms.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (val) {
                      setState(() {
                        val ? _selectedSymptoms.add(s) : _selectedSymptoms.remove(s);
                      });
                    },
                    // activeColor: AppColors.teal.withOpacity(0.2),
                    labelStyle: AppTextStyles.caption.copyWith(color: sel ? AppColors.teal : AppColors.textMuted),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              McDropdown<String>(
                hint: 'Body Part / Affected Area',
                value: _bodyPart,
                items: bodyParts,
                onChanged: (v) => setState(() => _bodyPart = v),
              ),
              const SizedBox(height: 12),

              CustomTextField(
                hint: 'Notes / Doctor\'s Advice',
                controller: _notesCtrl,
                prefixIcon: Icons.note_alt_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context, _followUpDateCtrl, (d) => _selectedFollowUpDate = d, firstDate: DateTime.now()),
                child: AbsorbPointer(
                  child: CustomTextField(
                    hint: 'Next Follow-up Date',
                    controller: _followUpDateCtrl,
                    prefixIcon: Icons.event_repeat,
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('Is this Hereditary?', style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: (hereditaryList.isEmpty 
                    ? ['Yes', 'No', 'Unknown'].map((e) => {'label': e, 'value': e.toLowerCase()}).toList() 
                    : hereditaryList).map((item) {
                  final val = item['label']!;
                  final isSelected = _hereditaryStatus == val;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _hereditaryStatus = val),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.bgCardNavy,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            val,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _ToggleCard(
                label: 'Hospitalization Required?',
                value: _isHospitalized,
                onChanged: (v) => setState(() => _isHospitalized = v),
                color: AppColors.orange,
              ),
              
              if (_isHospitalized) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, _admittedDateCtrl, (d) => _selectedAdmittedDate = d),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            hint: 'Admission Date',
                            controller: _admittedDateCtrl,
                            prefixIcon: Icons.login,
                            readOnly: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, _dischargedDateCtrl, (d) => _selectedDischargedDate = d),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            hint: 'Discharge Date',
                            controller: _dischargedDateCtrl,
                            prefixIcon: Icons.logout,
                            readOnly: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 36),

              CustomPrimaryButton(
                text: widget.disease == null ? 'Save Disease' : 'Update Disease',
                color: AppColors.teal,
                isLoading: controller.isLoading.value,
                onTap: () async {
                  if (_diseaseNameCtrl.text.isEmpty || _conditionType == null || _diagnosedDateCtrl.text.isEmpty) {
                     Get.snackbar("Error", "Please fill all mandatory fields (*)", 
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white);
                    return;
                  }

                  // Find internal values from labels
                  final selectedType = controller.conditionTypes.firstWhere((e) => e['label'] == _conditionType, orElse: () => {'value': _conditionType!.toLowerCase()})['value'];
                  final selectedStatus = (controller.statuses.isEmpty 
                      ? [{'label': _status, 'value': _status.toLowerCase()}] 
                      : controller.statuses).firstWhere((e) => e['label'] == _status, orElse: () => {'value': _status.toLowerCase()})['value'];
                  final selectedHereditary = (controller.hereditaryOptions.isEmpty 
                      ? [{'label': _hereditaryStatus, 'value': _hereditaryStatus.toLowerCase()}] 
                      : controller.hereditaryOptions).firstWhere((e) => e['label'] == _hereditaryStatus, orElse: () => {'value': _hereditaryStatus.toLowerCase()})['value'];
                  final selectedBodyPart = _bodyPart != null 
                      ? controller.bodyPartsOptions.firstWhere((e) => e['label'] == _bodyPart, orElse: () => {'value': _bodyPart!.toLowerCase()})['value'] 
                      : null;

                  bool success;
                  if (widget.disease == null) {
                    success = await controller.addDisease(
                      name: _diseaseNameCtrl.text,
                      icdCode: _icdCodeCtrl.text,
                      conditionType: selectedType!,
                      status: selectedStatus!,
                      severity: _severityLabel.toLowerCase(),
                      diagnosedOn: _diagnosedDateCtrl.text,
                      recoveredOn: _recoveredDateCtrl.text.isNotEmpty ? _recoveredDateCtrl.text : null,
                      bodyParts: selectedBodyPart != null ? [selectedBodyPart] : [],
                      hereditary: selectedHereditary!,
                      nextFollowUpOn: _followUpDateCtrl.text.isNotEmpty ? _followUpDateCtrl.text : null,
                      hospitalizationRequired: _isHospitalized,
                      admittedOn: _admittedDateCtrl.text.isNotEmpty ? _admittedDateCtrl.text : null,
                      dischargedOn: _dischargedDateCtrl.text.isNotEmpty ? _dischargedDateCtrl.text : null,
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
                      recoveredOn: _recoveredDateCtrl.text.isNotEmpty ? _recoveredDateCtrl.text : null,
                      bodyParts: selectedBodyPart != null ? [selectedBodyPart] : [],
                      hereditary: selectedHereditary!,
                      nextFollowUpOn: _followUpDateCtrl.text.isNotEmpty ? _followUpDateCtrl.text : null,
                      hospitalizationRequired: _isHospitalized,
                      admittedOn: _admittedDateCtrl.text.isNotEmpty ? _admittedDateCtrl.text : null,
                      dischargedOn: _dischargedDateCtrl.text.isNotEmpty ? _dischargedDateCtrl.text : null,
                      notes: _notesCtrl.text,
                      category: _categoryCtrl.text,
                    );
                  }

                  if (success) {
                    Get.back();
                    Get.snackbar("Success", widget.disease == null ? "Disease added successfully" : "Disease updated successfully",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white);
                  } else {
                    Get.snackbar("Error", "Failed to process request",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white);
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.heading3.copyWith(color: color)),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _ToggleCard({required this.label, required this.value, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? color.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textTail))),
          Switch(value: value, onChanged: onChanged,
              activeColor: color,
              activeTrackColor: color.withOpacity(0.1),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.black12,

          ),
        ],
      ),
    );
  }
}
