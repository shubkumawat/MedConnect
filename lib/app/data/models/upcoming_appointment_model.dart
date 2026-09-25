class UpcomingAppointment {
  final String uuid;
  final String? displayId;
  final String day;
  final String? scheduledAt;
  final String scheduledDate;
  final String scheduledTime;
  final String notes;
  final String kind;
  final String status;
  final String patientId;
  final String patientName;
  final bool isSelf;
  final String diseaseUuid;
  final String diseaseName;

  const UpcomingAppointment({
    required this.uuid,
    this.displayId,
    this.day = '',
    this.scheduledAt,
    this.scheduledDate = '',
    this.scheduledTime = '',
    this.notes = '',
    this.kind = 'follow_up',
    this.status = 'scheduled',
    this.patientId = '',
    this.patientName = '',
    this.isSelf = true,
    this.diseaseUuid = '',
    this.diseaseName = '',
  });

  String get kindLabel {
    switch (kind.toLowerCase()) {
      case 'initial':
        return 'Initial visit';
      case 'follow_up':
        return 'Follow-up';
      default:
        return kind.isEmpty ? 'Visit' : kind.replaceAll('_', ' ');
    }
  }

  String get dayLabel {
    switch (day.toLowerCase()) {
      case 'today':
        return 'Today';
      case 'tomorrow':
        return 'Tomorrow';
      default:
        return day.isEmpty ? 'Upcoming' : day;
    }
  }

  String get whenLabel {
    final time = scheduledTime.trim();
    if (time.isNotEmpty) return '${dayLabel} · $time';
    if (scheduledAt == null || scheduledAt!.isEmpty) return dayLabel;
    try {
      final dt = DateTime.parse(scheduledAt!).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$dayLabel · $h:$m $ap';
    } catch (_) {
      return dayLabel;
    }
  }

  /// Home / popup only show visits for today or tomorrow.
  bool get isTodayOrTomorrow {
    final label = day.toLowerCase().trim();
    if (label == 'today' || label == 'tomorrow') return true;
    final date = _resolvedDate;
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayOnly = DateTime(date.year, date.month, date.day);
    return dayOnly == today || dayOnly == tomorrow;
  }

  bool get isToday {
    if (day.toLowerCase().trim() == 'today') return true;
    final date = _resolvedDate;
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// True while the visit’s date/time is still ahead (past slots are hidden).
  bool get isStillUpcoming {
    final s = status.toLowerCase();
    if (s == 'visited' || s == 'cancelled') return false;
    final when = occursAt;
    if (when == null) return isTodayOrTomorrow;
    return !when.isBefore(DateTime.now());
  }

  /// Local date-time of the visit, or end of that day if no clock time.
  DateTime? get occursAt {
    final time = _parseClock(scheduledTime);
    if (scheduledAt != null && scheduledAt!.trim().isNotEmpty) {
      try {
        final parsed = DateTime.parse(scheduledAt!).toLocal();
        final raw = scheduledAt!;
        final hasClock = raw.contains('T') ||
            RegExp(r'\d{1,2}:\d{2}').hasMatch(raw);
        if (!hasClock && time != null) {
          return DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            time.$1,
            time.$2,
          );
        }
        return parsed;
      } catch (_) {}
    }
    final date = _resolvedDate;
    if (date != null) {
      if (time != null) {
        return DateTime(date.year, date.month, date.day, time.$1, time.$2);
      }
      return DateTime(date.year, date.month, date.day, 23, 59, 59);
    }
    final label = day.toLowerCase().trim();
    final now = DateTime.now();
    DateTime? dayAnchor;
    if (label == 'today') {
      dayAnchor = DateTime(now.year, now.month, now.day);
    } else if (label == 'tomorrow') {
      dayAnchor = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
    }
    if (dayAnchor == null) return null;
    if (time != null) {
      return DateTime(
        dayAnchor.year,
        dayAnchor.month,
        dayAnchor.day,
        time.$1,
        time.$2,
      );
    }
    return DateTime(dayAnchor.year, dayAnchor.month, dayAnchor.day, 23, 59, 59);
  }

  static (int, int)? _parseClock(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;
    final match = RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?\s*(am|pm)?').firstMatch(t);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final ap = match.group(3);
    if (ap == 'pm' && hour < 12) hour += 12;
    if (ap == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  DateTime? get _resolvedDate {
    if (scheduledAt != null && scheduledAt!.trim().isNotEmpty) {
      try {
        return DateTime.parse(scheduledAt!).toLocal();
      } catch (_) {}
    }
    final raw = scheduledDate.trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  static int compareNearTerm(UpcomingAppointment a, UpcomingAppointment b) {
    final at = a.occursAt;
    final bt = b.occursAt;
    if (at != null && bt != null) return at.compareTo(bt);
    final rank = (a.isToday ? 0 : 1).compareTo(b.isToday ? 0 : 1);
    if (rank != 0) return rank;
    return a.whenLabel.compareTo(b.whenLabel);
  }

  factory UpcomingAppointment.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    final disease = json['disease'];
    return UpcomingAppointment(
      uuid: json['uuid']?.toString() ?? '',
      displayId: json['display_id']?.toString(),
      day: json['day']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString(),
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      scheduledTime: json['scheduled_time']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'follow_up',
      status: json['status']?.toString() ?? 'scheduled',
      patientId: patient is Map
          ? (patient['patient_id']?.toString() ?? '')
          : '',
      patientName: patient is Map
          ? (patient['full_name']?.toString() ?? '')
          : '',
      isSelf: patient is Map ? patient['is_self'] == true : true,
      diseaseUuid: disease is Map ? (disease['uuid']?.toString() ?? '') : '',
      diseaseName: disease is Map ? (disease['name']?.toString() ?? '') : '',
    );
  }

  static List<UpcomingAppointment> listFrom(dynamic raw) {
    Map<String, dynamic>? block;
    if (raw is Map) {
      block = Map<String, dynamic>.from(raw);
    }
    final list = block != null
        ? (block['results'] is List ? block['results'] as List : null)
        : (raw is List ? raw : null);
    if (list == null) return [];
    final items = list
        .whereType<Map>()
        .map((e) => UpcomingAppointment.fromJson(Map<String, dynamic>.from(e)))
        .where((e) =>
            e.uuid.isNotEmpty && e.isTodayOrTomorrow && e.isStillUpcoming)
        .toList();
    items.sort(UpcomingAppointment.compareNearTerm);
    return items;
  }
}
