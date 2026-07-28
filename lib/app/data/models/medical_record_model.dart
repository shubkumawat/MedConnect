class MedicalRecord {
  final String id;
  final String name;
  final String status;
  final String diagnosedDate;
  final String doctorName;
  final String type; // 'disease', 'medication', 'vaccine'

  MedicalRecord({
    required this.id,
    required this.name,
    required this.status,
    required this.diagnosedDate,
    required this.doctorName,
    required this.type,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['record_id']?.toString() ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      diagnosedDate: json['diagnosed_date'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      type: json['record_type'] ?? 'disease',
    );
  }
}

class Medication {
  final String id;
  final String name;
  final String frequency;
  final String timing;
  final String diseaseName;
  final bool isReminderEnabled;

  Medication({
    required this.id,
    required this.name,
    required this.frequency,
    required this.timing,
    required this.diseaseName,
    this.isReminderEnabled = false,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['medication_id']?.toString() ?? '',
      name: json['name'] ?? '',
      frequency: json['frequency'] ?? '',
      timing: json['timing'] ?? '',
      diseaseName: json['disease_name'] ?? '',
      isReminderEnabled: json['is_reminder_enabled'] ?? false,
    );
  }
}

class TimelineEvent {
  final String id;
  final String title;
  final String time;
  final String type;
  final String colorCode;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.type,
    required this.colorCode,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['event_id']?.toString() ?? '',
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      colorCode: json['color_code'] ?? '#000000',
    );
  }
}
