class DiseaseModel {
  String id;
  String name;
  String type; // Chronic, Acute, etc.
  String status; // Active, Monitoring, etc.
  DateTime diagnosedDate;
  double severity; // 0.0 to 1.0
  List<String> symptoms;
  String bodyPart;
  bool hereditary;
  bool hospitalizationRequired;
  String notes;

  DiseaseModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.diagnosedDate,
    this.severity = 0.5,
    this.symptoms = const [],
    this.bodyPart = '',
    this.hereditary = false,
    this.hospitalizationRequired = false,
    this.notes = '',
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) => DiseaseModel(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    status: json['status'],
    diagnosedDate: DateTime.parse(json['diagnosedDate']),
    severity: json['severity']?.toDouble() ?? 0.5,
    symptoms: List<String>.from(json['symptoms'] ?? []),
    bodyPart: json['bodyPart'] ?? '',
    hereditary: json['hereditary'] ?? false,
    hospitalizationRequired: json['hospitalizationRequired'] ?? false,
    notes: json['notes'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'status': status,
    'diagnosedDate': diagnosedDate.toIso8601String(),
    'severity': severity,
    'symptoms': symptoms,
    'bodyPart': bodyPart,
    'hereditary': hereditary,
    'hospitalizationRequired': hospitalizationRequired,
    'notes': notes,
  };
}
