import 'package:flutter/material.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';

class AddDiseaseScreen extends StatefulWidget {
  const AddDiseaseScreen({super.key});

  @override
  State<AddDiseaseScreen> createState() => _AddDiseaseScreenState();
}

class _AddDiseaseScreenState extends State<AddDiseaseScreen> {
  final _diseaseNameCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _conditionType;
  String? _status;
  String? _consultationType;
  String? _bodyPart;

  double _severity = 2; // 1=Mild, 2=Moderate, 3=Severe
  bool _isHereditary = false;
  bool _isHospitalized = false;
  bool _isLoading = false;

  final List<String> _types = ['Chronic', 'Acute', 'Surgical', 'Genetic', 'Infectious', 'Allergy', 'Mental', 'Other'];
  final List<String> _statuses = ['Active', 'Monitoring', 'Resolved', 'In Remission'];
  final List<String> _consultTypes = ['In-clinic', 'Teleconsult', 'Emergency'];
  final List<String> _bodyParts = ['Head', 'Chest', 'Abdomen', 'Back', 'Arms', 'Legs', 'Whole Body', 'Other'];

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Add Disease / Condition',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Core Info Section ─────────────────────────────────────
            _SectionLabel(label: 'Core Info', color: AppColors.primary),
            const SizedBox(height: 14),

            CustomTextField(
              hint: 'Disease / Condition Name (autocomplete)',
              controller: _diseaseNameCtrl,
              prefixIcon: Icons.sick_outlined,
            ),
            const SizedBox(height: 12),

            McDropdown(
              hint: 'Condition Type',
              value: _conditionType,
              items: _types,
              onChanged: (v) => setState(() => _conditionType = v),
            ),
            const SizedBox(height: 12),

            McDropdown(
              hint: 'Status',
              value: _status,
              items: _statuses,
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 12),

            const CustomTextField(
              hint: 'Diagnosed Date',
              prefixIcon: Icons.calendar_today_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 16),

            // Severity slider
            Row(
              children: [
                Text('Severity:', style: AppTextStyles.caption),
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

            // Symptoms tags
            Text('Symptoms', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allSymptoms.map((s) {
                final sel = _selectedSymptoms.contains(s);
                return GestureDetector(
                  onTap: () => setState(() {
                    sel ? _selectedSymptoms.remove(s) : _selectedSymptoms.add(s);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teal.withOpacity(0.15) : AppColors.bgCardNavy,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.teal : AppColors.border),
                    ),
                    child: Text(
                      (sel ? '✓ ' : '+ ') + s,
                      style: AppTextStyles.captionBold.copyWith(
                        color: sel ? AppColors.accentTeal : AppColors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            McDropdown(
              hint: 'Body Part',
              value: _bodyPart,
              items: _bodyParts,
              onChanged: (v) => setState(() => _bodyPart = v),
            ),

            const SizedBox(height: 24),
            McDivider(),

            // ── Visit & Doctor Info ───────────────────────────────────
            _SectionLabel(label: 'Visit & Doctor Info', color: AppColors.teal),
            const SizedBox(height: 14),

            const CustomTextField(
              hint: 'Visit Date',
              prefixIcon: Icons.calendar_month_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 12),

            CustomTextField(
              hint: 'Doctor Name (search or type)',
              controller: _doctorCtrl,
              prefixIcon: Icons.person_pin_outlined,
            ),
            const SizedBox(height: 12),

            CustomTextField(
              hint: 'Hospital / Clinic',
              controller: _hospitalCtrl,
              prefixIcon: Icons.local_hospital_outlined,
            ),
            const SizedBox(height: 12),

            McDropdown(
              hint: 'Consultation Type',
              value: _consultationType,
              items: _consultTypes,
              onChanged: (v) => setState(() => _consultationType = v),
            ),
            const SizedBox(height: 12),

            CustomTextField(
              hint: 'Doctor Notes / Advice',
              controller: _notesCtrl,
              prefixIcon: Icons.note_alt_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Follow-up
            const CustomTextField(
              hint: 'Next Follow-up Date (sets reminder)',
              prefixIcon: Icons.event_outlined,
              readOnly: true,
            ),

            const SizedBox(height: 24),
            McDivider(),

            // ── Additional ────────────────────────────────────────────
            _SectionLabel(label: 'Additional Info', color: AppColors.orange),
            const SizedBox(height: 14),

            _ToggleCard(
              label: 'Hereditary?',
              value: _isHereditary,
              onChanged: (v) => setState(() => _isHereditary = v),
              color: AppColors.accentBlue,
            ),
            const SizedBox(height: 10),

            _ToggleCard(
              label: 'Hospitalization Required?',
              value: _isHospitalized,
              onChanged: (v) => setState(() => _isHospitalized = v),
              color: AppColors.orange,
            ),

            if (_isHospitalized) ...[
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: CustomTextField(hint: 'Admission Date', readOnly: true)),
                  SizedBox(width: 10),
                  Expanded(child: CustomTextField(hint: 'Discharge Date', readOnly: true)),
                ],
              ),
            ],

            const SizedBox(height: 36),

            CustomPrimaryButton(
              text: 'Save Disease',
              color: AppColors.teal,
              isLoading: _isLoading,
              onTap: () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(seconds: 1));
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
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
          Switch(value: value, onChanged: onChanged, activeColor: color, activeTrackColor: color.withOpacity(0.3)),
        ],
      ),
    );
  }
}
