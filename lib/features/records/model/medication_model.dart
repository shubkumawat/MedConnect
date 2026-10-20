class MedicationModel {
  String id;
  String name;
  String genericName;
  String dosage; // e.g. "500"
  String unit; // e.g. "mg"
  String form; // Tablet, Syrup, etc.
  String frequency; // Once daily, etc.
  String timing; // Before food, etc.
  DateTime startDate;
  DateTime? endDate;
  bool isOngoing;
  String prescribedBy;
  String linkedDiseaseId;
  String instructions;
  List<String> sideEffects;
  bool reminderEnabled;
  List<String> reminderTimes;
  int refillReminderDays;

  MedicationModel({
    required this.id,
    required this.name,
    this.genericName = '',
    required this.dosage,
    required this.unit,
    required this.form,
    required this.frequency,
    required this.timing,
    required this.startDate,
    this.endDate,
    this.isOngoing = true,
    this.prescribedBy = '',
    this.linkedDiseaseId = '',
    this.instructions = '',
    this.sideEffects = const [],
    this.reminderEnabled = true,
    this.reminderTimes = const [],
    this.refillReminderDays = 3,
  });
}
