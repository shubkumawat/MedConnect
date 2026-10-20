import 'package:get/get.dart';
import '../model/disease_model.dart';
import '../model/medication_model.dart';

class RecordsController extends GetxController {
  var diseases = <DiseaseModel>[].obs;
  var medications = <MedicationModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
  }

  void _loadDummyData() {
    diseases.value = [
      DiseaseModel(
        id: "1",
        name: "Hypertension",
        type: "Chronic",
        status: "Active",
        diagnosedDate: DateTime.now().subtract(const Duration(days: 365)),
        severity: 0.6,
        symptoms: ["Headache", "Dizziness"],
        bodyPart: "Circulatory System",
      ),
      DiseaseModel(
        id: "2",
        name: "Type 2 Diabetes",
        type: "Chronic",
        status: "Monitoring",
        diagnosedDate: DateTime.now().subtract(const Duration(days: 730)),
        severity: 0.4,
        symptoms: ["Fatigue", "Increased Thirst"],
        bodyPart: "Endocrine System",
      ),
    ];

    medications.value = [
      MedicationModel(
        id: "101",
        name: "Amlodipine",
        genericName: "Norvasc",
        dosage: "5",
        unit: "mg",
        form: "Tablet",
        frequency: "Once daily",
        timing: "Morning",
        startDate: DateTime.now().subtract(const Duration(days: 100)),
        linkedDiseaseId: "1",
      ),
    ];
  }

  void addDisease(DiseaseModel disease) {
    diseases.add(disease);
  }

  void updateDisease(DiseaseModel disease) {
    int index = diseases.indexWhere((element) => element.id == disease.id);
    if (index != -1) {
      diseases[index] = disease;
    }
  }

  void addMedication(MedicationModel medication) {
    medications.add(medication);
  }

  List<MedicationModel> getMedicationsForDisease(String diseaseId) {
    return medications.where((m) => m.linkedDiseaseId == diseaseId).toList();
  }
}
