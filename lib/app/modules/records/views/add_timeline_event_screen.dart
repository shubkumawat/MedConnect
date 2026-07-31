import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/records_controller.dart';
import 'package:intl/intl.dart';

class AddTimelineEventScreen extends StatefulWidget {
  final String diseaseUuid;
  const AddTimelineEventScreen({super.key, required this.diseaseUuid});

  @override
  State<AddTimelineEventScreen> createState() => _AddTimelineEventScreenState();
}

class _AddTimelineEventScreenState extends State<AddTimelineEventScreen> {
  final RecordsController controller = Get.find<RecordsController>();
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _notesCtrl = TextEditingController();

  String _selectedType = 'doc';
  final List<Map<String, dynamic>> _types = [
    {'label': 'Document', 'value': 'doc', 'icon': Icons.description, 'color': '#2196F3'},
    {'label': 'Hospital', 'value': 'hosp', 'icon': Icons.local_hospital, 'color': '#E91E63'},
    {'label': 'Note', 'value': 'note', 'icon': Icons.note, 'color': '#9C27B0'},
    {'label': 'Lab Result', 'value': 'lab', 'icon': Icons.science, 'color': '#4CAF50'},
    {'label': 'Surgery', 'value': 'surgery', 'icon': Icons.healing, 'color': '#F44336'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Add to Timeline', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Details', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            CustomTextField(
              hint: 'Event Title (e.g. Follow-up Visit)',
              controller: _titleCtrl,
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
                }
              },
              child: AbsorbPointer(
                child: CustomTextField(
                  hint: 'Date',
                  controller: _dateCtrl,
                  prefixIcon: Icons.calendar_today,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              hint: 'Additional Notes',
              controller: _notesCtrl,
              maxLines: 3,
              prefixIcon: Icons.notes,
            ),
            const SizedBox(height: 24),
            Text('Event Type', style: AppTextStyles.captionBold),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _types.length,
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = _selectedType == type['value'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type['value']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.teal.withOpacity(0.1) : AppColors.bgCardNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.teal : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type['icon'], color: isSelected ? AppColors.teal : AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          type['label'],
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? AppColors.teal : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Obx(() => CustomPrimaryButton(
              text: 'Add to Timeline',
              color: AppColors.teal,
              isLoading: controller.isTimelineLoading.value,
              onTap: () async {
                if (_titleCtrl.text.isEmpty) {
                  Get.snackbar("Error", "Please enter a title");
                  return;
                }
                final selectedTypeData = _types.firstWhere((e) => e['value'] == _selectedType);
                bool success = await controller.addTimelineEvent(
                  diseaseUuid: widget.diseaseUuid,
                  title: _titleCtrl.text,
                  type: _selectedType,
                  date: _dateCtrl.text,
                  notes: _notesCtrl.text,
                  colorCode: selectedTypeData['color'],
                );

                if (success) {
                  Get.back();
                  Get.snackbar("Success", "Timeline event added");
                } else {
                  Get.snackbar("Error", "Failed to add event");
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}
