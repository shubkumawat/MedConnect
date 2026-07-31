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
  final List<String> timingSlots;
  final String diseaseName;
  final bool isReminderEnabled;
  final String? genericName;
  final String? strength;
  final String? dosage;
  final String? dosageUnit;
  final String? form;
  final String? withFood;
  final String? startDate;
  final String? endDate;
  final bool isOngoing;
  final String? prescribedBy;
  final String? instructions;
  final bool isActive;

  Medication({
    required this.id,
    required this.name,
    required this.frequency,
    required this.timing,
    this.timingSlots = const [],
    required this.diseaseName,
    this.isReminderEnabled = false,
    this.genericName,
    this.strength,
    this.dosage,
    this.dosageUnit,
    this.form,
    this.withFood,
    this.startDate,
    this.endDate,
    this.isOngoing = false,
    this.prescribedBy,
    this.instructions,
    this.isActive = true,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    List<String> slots = [];
    final rawTiming = json['timing'];
    if (rawTiming is List) {
      slots = rawTiming.map((e) => e.toString()).toList();
    } else if (rawTiming != null && rawTiming.toString().isNotEmpty) {
      slots = rawTiming
          .toString()
          .split(RegExp(r'[,|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final strength = json['strength']?.toString();
    final dosage = json['dosage']?.toString();

    return Medication(
      id: json['uuid']?.toString() ??
          json['medication_id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? json['medicine_name']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      timing: slots.isNotEmpty ? slots.join(', ') : (rawTiming?.toString() ?? ''),
      timingSlots: slots,
      diseaseName: json['disease_name']?.toString() ?? '',
      isReminderEnabled: json['is_reminder_enabled'] == true ||
          json['reminder_enabled'] == true,
      genericName: json['generic_name']?.toString(),
      strength: strength,
      dosage: dosage,
      dosageUnit: json['dosage_unit']?.toString() ?? json['unit']?.toString(),
      form: json['form']?.toString() ?? json['dosage_form']?.toString(),
      withFood: json['with_food']?.toString(),
      startDate: json['start_date']?.toString() ?? json['started_on']?.toString(),
      endDate: json['end_date']?.toString() ?? json['ended_on']?.toString(),
      isOngoing: json['is_ongoing'] == true || json['ongoing'] == true,
      prescribedBy: json['prescribed_by']?.toString() ??
          json['doctor_name']?.toString(),
      instructions: json['instructions']?.toString() ?? json['notes']?.toString(),
      isActive: json['is_active'] != false && json['active'] != false,
    );
  }

  String get subtitle {
    final parts = <String>[
      if (strength != null && strength!.isNotEmpty) strength!,
      if (dosage != null && dosage!.isNotEmpty) dosage!,
      if (frequency.isNotEmpty) frequencyDisplay,
      if (timing.isNotEmpty) timing,
      if (withFood != null && withFood!.isNotEmpty) withFood!.replaceAll('_', ' '),
    ];
    return parts.join(' · ');
  }

  /// UI-friendly frequency (API still stores 1-0-0 / SOS etc.)
  String get frequencyDisplay {
    const map = {
      '1-0-0': 'Once daily',
      '0-1-0': 'Once daily',
      '0-0-1': 'Once daily',
      '1-0-1': 'Twice daily',
      '1-1-0': 'Twice daily',
      '0-1-1': 'Twice daily',
      '1-1-1': 'Three times daily',
      '1-1-1-1': 'Four times daily',
      'every_6_hours': 'Every 6 hours',
      'every_8_hours': 'Every 8 hours',
      'SOS': 'As needed (SOS)',
    };
    return map[frequency] ?? frequency;
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
      id: json['event_id']?.toString() ?? json['uuid']?.toString() ?? '',
      title: json['title'] ?? '',
      time: json['time'] ?? json['event_date']?.toString() ?? '',
      type: json['type'] ?? json['event_type'] ?? '',
      colorCode: json['color_code'] ?? '#000000',
    );
  }
}
