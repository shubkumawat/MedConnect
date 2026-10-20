import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/records_controller.dart';
import '../model/disease_model.dart';
import 'add_medication_screen.dart';

class AddDiseaseScreen extends StatefulWidget {
  const AddDiseaseScreen({super.key});

  @override
  State<AddDiseaseScreen> createState() => _AddDiseaseScreenState();
}

class _AddDiseaseScreenState extends State<AddDiseaseScreen> {
  final controller = Get.find<RecordsController>();
  final nameController = TextEditingController();
  final notesController = TextEditingController();
  final symptomsController = TextEditingController();

  String selectedType = 'Chronic';
  String selectedStatus = 'Active';
  DateTime diagnosedDate = DateTime.now();
  double severity = 0.5;
  List<String> symptoms = [];
  String bodyPart = 'Other';
  bool hereditary = false;
  bool hospitalization = false;

  final List<String> types = ['Chronic', 'Acute', 'Surgical', 'Genetic', 'Infectious', 'Allergy', 'Mental', 'Other'];
  final List<String> statuses = ['Active', 'Monitoring', 'Resolved', 'In Remission'];
  final List<String> bodyParts = ['Head', 'Chest', 'Abdomen', 'Circulatory System', 'Endocrine System', 'Musculoskeletal', 'Other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text("Add Condition"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Condition Name"),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("e.g. Type 2 Diabetes"),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Type"),
                      _buildDropdown(selectedType, types, (val) => setState(() => selectedType = val!)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Status"),
                      _buildDropdown(selectedStatus, statuses, (val) => setState(() => selectedStatus = val!)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel("Diagnosed Date"),
            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: diagnosedDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => diagnosedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: AppColors.primaryDeepBlue, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${diagnosedDate.day}/${diagnosedDate.month}/${diagnosedDate.year}", style: const TextStyle(color: Colors.white)),
                    const Icon(Icons.calendar_today, color: AppColors.accentTeal, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel("Severity"),
            Row(
              children: [
                const Text("Mild", style: TextStyle(color: Colors.white60, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: severity,
                    onChanged: (val) => setState(() => severity = val),
                    activeColor: AppColors.accentTeal,
                    inactiveColor: Colors.white10,
                  ),
                ),
                const Text("Severe", style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel("Symptoms"),
            TextField(
              controller: symptomsController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Add symptom...").copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.accentTeal),
                  onPressed: () {
                    if (symptomsController.text.isNotEmpty) {
                      setState(() {
                        symptoms.add(symptomsController.text);
                        symptomsController.clear();
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: symptoms.map((s) => Chip(
                label: Text(s, style: const TextStyle(color: AppColors.primaryDeepBlue)),
                backgroundColor: AppColors.accentTeal,
                onDeleted: () => setState(() => symptoms.remove(s)),
              )).toList(),
            ),
            const SizedBox(height: 20),
            _buildLabel("Body Part"),
            _buildDropdown(bodyPart, bodyParts, (val) => setState(() => bodyPart = val!)),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("Hereditary?", style: TextStyle(color: Colors.white)),
              value: hereditary,
              onChanged: (val) => setState(() => hereditary = val),
              activeColor: AppColors.accentTeal,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text("Hospitalization Required?", style: TextStyle(color: Colors.white)),
              value: hospitalization,
              onChanged: (val) => setState(() => hospitalization = val),
              activeColor: AppColors.accentTeal,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            _buildLabel("Notes"),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Any additional information"),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Save Condition", style: TextStyle(color: AppColors.primaryDeepBlue, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (nameController.text.isEmpty) {
      Get.snackbar("Error", "Please enter condition name");
      return;
    }

    final newDisease = DiseaseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      type: selectedType,
      status: selectedStatus,
      diagnosedDate: diagnosedDate,
      severity: severity,
      symptoms: symptoms,
      bodyPart: bodyPart,
      hereditary: hereditary,
      hospitalizationRequired: hospitalization,
      notes: notesController.text,
    );

    controller.addDisease(newDisease);
    
    Get.defaultDialog(
      title: "Saved!",
      middleText: "Condition added successfully. Would you like to add medication for this?",
      backgroundColor: AppColors.primaryDeepBlue,
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      confirm: TextButton(
        onPressed: () {
          Get.back(); // Close dialog
          Get.off(() => AddMedicationScreen(linkedDiseaseId: newDisease.id));
        },
        child: const Text("Yes, Add Medication", style: TextStyle(color: AppColors.accentTeal)),
      ),
      cancel: TextButton(
        onPressed: () {
          Get.back(); // Close dialog
          Get.back(); // Go back to list
        },
        child: const Text("No, Later", style: TextStyle(color: Colors.white60)),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(text, style: AppTextStyles.poppinsMedium16),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
    filled: true,
    fillColor: AppColors.primaryDeepBlue,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: AppColors.primaryDeepBlue, borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.primaryDeepBlue,
        style: const TextStyle(color: Colors.white),
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
