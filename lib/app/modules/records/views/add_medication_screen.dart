import 'package:flutter/material.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _medNameCtrl = TextEditingController();
  final _genericCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController(text: '500');

  String? _dosageUnit = 'mg';
  String? _form;
  String? _frequency;
  String? _timing;
  String? _linkedDisease;
  bool _isOngoing = false;
  bool _reminderEnabled = true;
  bool _isLoading = false;

  // reminder times
  final List<String> _reminderTimes = ['8:00 AM'];

  final _forms = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Inhaler', 'Topical', 'Patch'];
  final _frequencies = ['Once daily', 'Twice daily', '3x daily', '4x daily', 'Every 6 hours', 'Every 8 hours', 'SOS'];
  final _timings = ['Before Food', 'After Food', 'With Food', 'Bedtime', 'Empty Stomach'];
  final _units = ['mg', 'ml', 'IU', 'g'];
  final _diseases = ['Type 2 Diabetes', 'Hypertension', 'Hernia (Inguinal)'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(title: '💊 Add Medication', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            const SizedBox(height: 20),
            McDivider(),

            // ── Schedule & Link ───────────────────────────────────────
            _SectionBadge('Schedule & Link', AppColors.primary),
            const SizedBox(height: 14),

            Row(
              children: [
                const Expanded(child: CustomTextField(hint: 'Start Date', prefixIcon: Icons.calendar_today_outlined, readOnly: true)),
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
                      : const CustomTextField(hint: 'End Date', prefixIcon: Icons.event_outlined, readOnly: true),
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

            const CustomTextField(hint: 'Prescribed By (doctor search)', prefixIcon: Icons.person_pin_outlined),
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

            const SizedBox(height: 16),

            // Prescription upload
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgCardNavy,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file, color: AppColors.accentTeal, size: 22),
                    const SizedBox(width: 10),
                    Text('Upload Prescription (AI OCR auto-fill)', style: AppTextStyles.tealLabel.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            CustomPrimaryButton(
              text: 'Save Medication',
              color: AppColors.teal,
              isLoading: _isLoading,
              icon: Icons.check,
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
