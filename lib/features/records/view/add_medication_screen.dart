import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/records_controller.dart';
import '../model/medication_model.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? linkedDiseaseId;
  const AddMedicationScreen({super.key, this.linkedDiseaseId});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final controller = Get.find<RecordsController>();
  
  final nameController = TextEditingController();
  final genericController = TextEditingController();
  final dosageController = TextEditingController();
  final instructionsController = TextEditingController();
  final sideEffectsController = TextEditingController();

  String selectedUnit = 'mg';
  String selectedForm = 'Tablet';
  String selectedFrequency = 'Once daily';
  String selectedTiming = 'After Food';
  DateTime startDate = DateTime.now();
  bool isOngoing = true;
  String? selectedDiseaseId;
  List<String> sideEffects = [];

  final List<String> units = ['mg', 'ml', 'IU', 'g', 'mcg'];
  final List<String> forms = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Drops', 'Inhaler', 'Topical', 'Patch'];
  final List<String> frequencies = ['Once daily', 'Twice daily', '3x daily', '4x daily', 'Every 8 hours', 'Every 12 hours', 'SOS'];
  final List<String> timings = ['Before Food', 'After Food', 'With Food', 'Bedtime'];

  @override
  void initState() {
    super.initState();
    selectedDiseaseId = widget.linkedDiseaseId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text("Add Medication"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Medication Name"),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("e.g. Amlodipine"),
            ),
            const SizedBox(height: 16),
            _buildLabel("Generic Name (Optional)"),
            TextField(
              controller: genericController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("e.g. Norvasc"),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Dosage"),
                      TextField(
                        controller: dosageController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Amount"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Unit"),
                      _buildDropdown(selectedUnit, units, (val) => setState(() => selectedUnit = val!)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel("Dosage Form"),
            _buildDropdown(selectedForm, forms, (val) => setState(() => selectedForm = val!)),
            const SizedBox(height: 16),
            _buildLabel("Frequency"),
            _buildDropdown(selectedFrequency, frequencies, (val) => setState(() => selectedFrequency = val!)),
            const SizedBox(height: 16),
            _buildLabel("Timing"),
            _buildDropdown(selectedTiming, timings, (val) => setState(() => selectedTiming = val!)),
            const SizedBox(height: 16),
            _buildLabel("Linked Condition"),
            Obx(() => _buildDropdown(
              selectedDiseaseId ?? 'None', 
              ['None', ...controller.diseases.map((d) => d.id)],
              (val) => setState(() => selectedDiseaseId = val == 'None' ? null : val),
              itemLabels: {'None': 'General / Not Linked', ...{for (var d in controller.diseases) d.id: d.name}}
            )),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Ongoing Medication", style: TextStyle(color: Colors.white)),
              value: isOngoing,
              onChanged: (val) => setState(() => isOngoing = val),
              activeColor: AppColors.accentTeal,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            _buildLabel("Special Instructions"),
            TextField(
              controller: instructionsController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("e.g. Avoid grapefruit"),
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
                child: const Text("Save Medication", style: TextStyle(color: AppColors.primaryDeepBlue, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    if (nameController.text.isEmpty || dosageController.text.isEmpty) {
      Get.snackbar("Error", "Please fill name and dosage");
      return;
    }

    final newMed = MedicationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameController.text,
      genericName: genericController.text,
      dosage: dosageController.text,
      unit: selectedUnit,
      form: selectedForm,
      frequency: selectedFrequency,
      timing: selectedTiming,
      startDate: startDate,
      isOngoing: isOngoing,
      linkedDiseaseId: selectedDiseaseId ?? '',
      instructions: instructionsController.text,
    );

    controller.addMedication(newMed);
    Get.back();
    Get.snackbar("Success", "Medication added successfully", backgroundColor: AppColors.accentTeal, colorText: AppColors.primaryDeepBlue);
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

  Widget _buildDropdown(String value, List<String> items, Function(String?) onChanged, {Map<String, String>? itemLabels}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: AppColors.primaryDeepBlue, borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: items.contains(value) ? value : items.first,
        dropdownColor: AppColors.primaryDeepBlue,
        style: const TextStyle(color: Colors.white),
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemLabels?[e] ?? e))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
