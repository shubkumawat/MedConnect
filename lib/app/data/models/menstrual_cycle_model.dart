class MenstrualCycle {
  final bool available;
  final bool isConfigured;
  final bool isEnabled;
  final String? lastPeriodStart;
  final int cycleLengthDays;
  final int periodLengthDays;
  final String reminderTime;
  final bool remindDayBefore;
  final bool remindOnStart;
  final String? nextPeriodOn;
  final String? periodEndOn;
  final String? ovulationOn;
  final String? nextReminderOn;

  const MenstrualCycle({
    this.available = true,
    this.isConfigured = false,
    this.isEnabled = true,
    this.lastPeriodStart,
    this.cycleLengthDays = 28,
    this.periodLengthDays = 5,
    this.reminderTime = '09:00',
    this.remindDayBefore = true,
    this.remindOnStart = true,
    this.nextPeriodOn,
    this.periodEndOn,
    this.ovulationOn,
    this.nextReminderOn,
  });

  factory MenstrualCycle.fromJson(Map<String, dynamic> json) {
    return MenstrualCycle(
      available: json['available'] != false,
      isConfigured: json['is_configured'] == true,
      isEnabled: json['is_enabled'] != false,
      lastPeriodStart: _date(json['last_period_start']),
      cycleLengthDays: _int(json['cycle_length_days'], 28),
      periodLengthDays: _int(json['period_length_days'], 5),
      reminderTime: (json['reminder_time']?.toString().trim().isNotEmpty == true)
          ? json['reminder_time'].toString().trim()
          : '09:00',
      remindDayBefore: json['remind_day_before'] != false,
      remindOnStart: json['remind_on_start'] != false,
      nextPeriodOn: _date(json['next_period_on']),
      periodEndOn: _date(json['period_end_on']),
      ovulationOn: _date(json['ovulation_on']),
      nextReminderOn: json['next_reminder_on']?.toString(),
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  static String? _date(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class ParentPermission {
  final bool required;
  final String status;
  final bool canRespond;
  final String? parentName;
  final String? parentPatientId;
  final String? childName;
  final String? message;

  const ParentPermission({
    this.required = false,
    this.status = '',
    this.canRespond = false,
    this.parentName,
    this.parentPatientId,
    this.childName,
    this.message,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isGranted => status.toLowerCase() == 'granted';
  bool get isDeclined =>
      status.toLowerCase() == 'declined' || status.toLowerCase() == 'denied';

  /// Parent cannot open this adult's health records until granted.
  bool get recordsLocked => required && !isGranted;

  String get statusLabel {
    if (isGranted) return 'Permission granted';
    if (isDeclined) return 'Permission declined';
    if (isPending) return 'Waiting for permission';
    return status.isEmpty ? 'No request' : status;
  }

  factory ParentPermission.fromJson(Map<String, dynamic> json) {
    final nested = json['parent_permission'];
    final src = nested is Map
        ? Map<String, dynamic>.from(nested)
        : json;
    return ParentPermission(
      required: src['required'] == true,
      status: (src['status'] ?? '').toString(),
      canRespond: src['can_respond'] == true,
      parentName: src['parent_name']?.toString(),
      parentPatientId: src['parent_patient_id']?.toString(),
      childName: src['child_name']?.toString() ?? src['name']?.toString(),
      message: src['message']?.toString(),
    );
  }

  static ParentPermission? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final parsed = ParentPermission.fromJson(Map<String, dynamic>.from(raw));
    if (!parsed.required &&
        !parsed.isPending &&
        !parsed.isGranted &&
        !parsed.isDeclined) {
      return null;
    }
    return parsed;
  }
}
