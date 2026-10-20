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

class MedicationDoseToday {
  final String? reminderUuid;
  final String time;
  final String? scheduledFor;
  final String status;
  final String? actedAt;

  const MedicationDoseToday({
    this.reminderUuid,
    required this.time,
    this.scheduledFor,
    required this.status,
    this.actedAt,
  });

  factory MedicationDoseToday.fromJson(Map<String, dynamic> json) {
    return MedicationDoseToday(
      reminderUuid: json['reminder_uuid']?.toString(),
      time: json['time']?.toString() ?? '',
      scheduledFor: json['scheduled_for']?.toString(),
      status: (json['status']?.toString() ?? 'scheduled').toLowerCase(),
      actedAt: json['acted_at']?.toString(),
    );
  }

  bool get isTaken => status == 'taken' || status == 'completed';
  bool get canMarkTaken => !isTaken && time.isNotEmpty;
}

class MedicationReminder {
  final String id;
  final String displayId;
  final List<String> times;
  final List<String> daysOfWeek;
  final String? startDate;
  final String? endDate;
  final bool isEnabled;
  final List<String> scheduleTimes;
  final List<String> takenTimes;
  final List<MedicationDoseToday> dosesToday;
  final String? nextDoseTime;

  const MedicationReminder({
    required this.id,
    this.displayId = '',
    this.times = const [],
    this.daysOfWeek = const [],
    this.startDate,
    this.endDate,
    this.isEnabled = true,
    this.scheduleTimes = const [],
    this.takenTimes = const [],
    this.dosesToday = const [],
    this.nextDoseTime,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    List<String> asStringList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    final doses = <MedicationDoseToday>[];
    final rawDoses = json['doses_today'];
    if (rawDoses is List) {
      for (final e in rawDoses) {
        if (e is Map) {
          doses.add(MedicationDoseToday.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final times = asStringList(json['times']);
    final schedule = asStringList(json['schedule_times']);

    return MedicationReminder(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      displayId: json['display_id']?.toString() ?? '',
      times: times,
      daysOfWeek: asStringList(json['days_of_week']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      isEnabled: json['is_enabled'] != false,
      scheduleTimes: schedule.isNotEmpty ? schedule : times,
      takenTimes: asStringList(json['taken_times']),
      dosesToday: doses,
      nextDoseTime: json['next_dose_time']?.toString(),
    );
  }

  List<String> get displayTimes =>
      scheduleTimes.isNotEmpty ? scheduleTimes : times;
}

class Medication {
  final String id;
  final String name;
  final String frequency;
  final String timing;
  final List<String> timingSlots;
  final String diseaseName;
  final String? diseaseUuid;
  final bool isReminderEnabled;
  final String? genericName;
  final String? strength;
  final String? dosage;
  final String? dosageUnit;
  final String? form;
  final String? withFood;
  final List<String> sideEffects;
  final List<String> allergies;
  final String? startDate;
  final String? endDate;
  final bool isOngoing;
  final String? prescribedBy;
  final String? instructions;
  final bool isActive;
  final MedicationReminder? primaryReminder;
  final List<MedicationReminder> reminders;
  final List<MedicationDoseToday> dosesToday;

  Medication({
    required this.id,
    required this.name,
    required this.frequency,
    required this.timing,
    this.timingSlots = const [],
    required this.diseaseName,
    this.diseaseUuid,
    this.isReminderEnabled = false,
    this.genericName,
    this.strength,
    this.dosage,
    this.dosageUnit,
    this.form,
    this.withFood,
    this.sideEffects = const [],
    this.allergies = const [],
    this.startDate,
    this.endDate,
    this.isOngoing = false,
    this.prescribedBy,
    this.instructions,
    this.isActive = true,
    this.primaryReminder,
    this.reminders = const [],
    this.dosesToday = const [],
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

    MedicationReminder? primary;
    final rawPrimary = json['primary_reminder'];
    if (rawPrimary is Map) {
      primary =
          MedicationReminder.fromJson(Map<String, dynamic>.from(rawPrimary));
    }

    final reminderList = <MedicationReminder>[];
    final rawReminders = json['reminders'];
    if (rawReminders is List) {
      for (final e in rawReminders) {
        if (e is Map) {
          reminderList.add(
              MedicationReminder.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final doses = <MedicationDoseToday>[];
    final rawDoses = json['doses_today'];
    if (rawDoses is List) {
      for (final e in rawDoses) {
        if (e is Map) {
          doses.add(MedicationDoseToday.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    } else if (primary != null && primary.dosesToday.isNotEmpty) {
      doses.addAll(primary.dosesToday.map((d) => MedicationDoseToday(
            reminderUuid: d.reminderUuid ?? primary!.id,
            time: d.time,
            scheduledFor: d.scheduledFor,
            status: d.status,
            actedAt: d.actedAt,
          )));
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
      diseaseUuid: json['disease_uuid']?.toString(),
      isReminderEnabled: json['is_reminder_enabled'] == true ||
          json['reminder_enabled'] == true,
      genericName: json['generic_name']?.toString(),
      strength: strength,
      dosage: dosage,
      dosageUnit: json['dosage_unit']?.toString() ?? json['unit']?.toString(),
      form: json['form']?.toString() ?? json['dosage_form']?.toString(),
      withFood: json['with_food']?.toString(),
      sideEffects: _parseStringList(
        json['side_effects'] ?? json['side_effects_noted'],
      ),
      allergies: _parseStringList(json['allergies']),
      startDate: json['start_date']?.toString() ?? json['started_on']?.toString(),
      endDate: json['end_date']?.toString() ?? json['ended_on']?.toString(),
      isOngoing: json['is_ongoing'] == true || json['ongoing'] == true,
      prescribedBy: json['prescribed_by']?.toString() ??
          json['doctor_name']?.toString(),
      instructions: json['instructions']?.toString() ?? json['notes']?.toString(),
      isActive: json['is_active'] != false &&
          json['active'] != false &&
          json['is_archived'] != true,
      primaryReminder: primary,
      reminders: reminderList,
      dosesToday: doses,
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return (e['name'] ??
                      e['allergy_name'] ??
                      e['side_effect'] ??
                      e['label'] ??
                      '')
                  .toString();
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    if (s.startsWith('[') && s.endsWith(']')) {
      final inner = s.substring(1, s.length - 1);
      return inner
          .split(',')
          .map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return s
        .split(RegExp(r'[,|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
      'weekly': 'Weekly',
      'SOS': 'As needed (SOS)',
    };
    final everyDays = RegExp(r'^every_(\d+)_days$').firstMatch(frequency);
    if (everyDays != null) {
      final n = everyDays.group(1);
      return 'Every $n days';
    }
    return map[frequency] ?? frequency;
  }

  String? get nextDoseTime =>
      primaryReminder?.nextDoseTime ??
      (dosesToday.isNotEmpty
          ? dosesToday
              .firstWhere(
                (d) => d.canMarkTaken,
                orElse: () => dosesToday.first,
              )
              .time
          : null);

  List<String> get reminderTimes =>
      primaryReminder?.displayTimes ??
      (reminders.isNotEmpty ? reminders.first.displayTimes : const []);
}

class TimelineEvent {
  final String id;
  final String title;
  final String time;
  final String type;
  final String colorCode;
  final String description;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.time,
    required this.type,
    required this.colorCode,
    this.description = '',
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    final type =
        (json['type'] ?? json['event_type'] ?? '').toString().toLowerCase();
    return TimelineEvent(
      id: json['event_id']?.toString() ?? json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      time: _formatTimelineTime(
        json['time'] ?? json['event_date'] ?? json['created_at'],
      ),
      type: type,
      colorCode: json['color_code']?.toString() ?? _colorForEventType(type),
      description: json['description']?.toString() ?? '',
    );
  }

  static String _formatTimelineTime(dynamic raw) {
    if (raw == null) return '';
    final value = raw.toString().trim();
    if (value.isEmpty) return '';
    try {
      final dt = DateTime.parse(value).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} · $h:$m $ampm';
    } catch (_) {
      return value;
    }
  }

  static String _colorForEventType(String type) {
    switch (type) {
      case 'medication_added':
      case 'med':
        return '#E07B2A';
      case 'document_added':
      case 'doc':
        return '#3D8EE8';
      case 'disease_created':
      case 'disease_updated':
        return '#1B9E8E';
      case 'qr':
        return '#0B6E4F';
      case 'hosp':
        return '#E03A3A';
      case 'vac':
        return '#1FAD6E';
      default:
        return '#167A6D';
    }
  }
}
