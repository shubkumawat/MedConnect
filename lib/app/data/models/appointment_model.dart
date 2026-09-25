class DiseaseAppointment {
  final String uuid;
  final String? displayId;
  final bool isArchived;
  final String? createdAt;
  final String? updatedAt;
  final String? scheduledAt;
  final String notes;
  final String kind;
  final String status;

  DiseaseAppointment({
    required this.uuid,
    this.displayId,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
    this.scheduledAt,
    this.notes = '',
    this.kind = 'follow_up',
    this.status = 'scheduled',
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isScheduled => status.toLowerCase() == 'scheduled';
  bool get isInitial => kind.toLowerCase() == 'initial';
  bool get isFollowUp => kind.toLowerCase() == 'follow_up';

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

  String get statusLabel {
    if (status.isEmpty) return 'Scheduled';
    return status[0].toUpperCase() + status.substring(1);
  }

  String get whenLabel {
    if (scheduledAt == null || scheduledAt!.isEmpty) return 'Date not set';
    try {
      final dt = DateTime.parse(scheduledAt!).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} · $h:$m $ap';
    } catch (_) {
      return scheduledAt!;
    }
  }

  factory DiseaseAppointment.fromJson(Map<String, dynamic> json) {
    return DiseaseAppointment(
      uuid: json['uuid']?.toString() ?? '',
      displayId: json['display_id']?.toString(),
      isArchived: json['is_archived'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      scheduledAt: json['scheduled_at']?.toString(),
      notes: json['notes']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'follow_up',
      status: json['status']?.toString() ?? 'scheduled',
    );
  }

  static DiseaseAppointment? tryParse(dynamic raw) {
    if (raw is Map && (raw['uuid']?.toString().isNotEmpty ?? false)) {
      return DiseaseAppointment.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  static List<DiseaseAppointment> listFrom(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => DiseaseAppointment.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.uuid.isNotEmpty)
        .toList();
  }
}

class AppointmentDetail extends DiseaseAppointment {
  final List<Map<String, dynamic>> symptoms;
  final List<Map<String, dynamic>> doctors;
  final List<Map<String, dynamic>> hospitals;
  final List<Map<String, dynamic>> medications;
  final List<Map<String, dynamic>> documents;
  final List<Map<String, dynamic>> receipts;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> prescriptions;

  AppointmentDetail({
    required super.uuid,
    super.displayId,
    super.isArchived,
    super.createdAt,
    super.updatedAt,
    super.scheduledAt,
    super.notes,
    super.kind,
    super.status,
    this.symptoms = const [],
    this.doctors = const [],
    this.hospitals = const [],
    this.medications = const [],
    this.documents = const [],
    this.receipts = const [],
    this.attachments = const [],
    this.prescriptions = const [],
  });

  factory AppointmentDetail.fromJson(Map<String, dynamic> json) {
    final base = DiseaseAppointment.fromJson(json);
    return AppointmentDetail(
      uuid: base.uuid,
      displayId: base.displayId,
      isArchived: base.isArchived,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      scheduledAt: base.scheduledAt,
      notes: base.notes,
      kind: base.kind,
      status: base.status,
      symptoms: _maps(json['symptoms']),
      doctors: _maps(json['doctors']),
      hospitals: _maps(json['hospitals']),
      medications: _maps(json['medications']),
      documents: _maps(json['documents']),
      receipts: _maps(json['receipts']),
      attachments: _maps(json['attachments']),
      prescriptions: _maps(json['prescriptions']),
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
