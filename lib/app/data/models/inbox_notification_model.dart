class InboxNotification {
  final String uuid;
  final String displayId;
  final String patientId;
  final String type;
  final String typeLabel;
  final String priority;
  final String status;
  final bool isRead;
  final String title;
  final String body;
  final String deepLink;
  final String sourceType;
  final String? sourceUuid;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final DateTime? readAt;

  InboxNotification({
    required this.uuid,
    required this.displayId,
    required this.patientId,
    required this.type,
    required this.typeLabel,
    required this.priority,
    required this.status,
    required this.isRead,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.sourceType,
    this.sourceUuid,
    this.createdAt,
    this.sentAt,
    this.readAt,
  });

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      uuid: json['uuid']?.toString() ?? '',
      displayId: json['display_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      type: json['notification_type']?.toString() ?? '',
      typeLabel: json['notification_type_label']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isRead: json['is_read'] == true ||
          json['status']?.toString().toLowerCase() == 'read',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      deepLink: json['deep_link']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? '',
      sourceUuid: json['source_uuid']?.toString(),
      createdAt: _dt(json['created_at']),
      sentAt: _dt(json['sent_at']),
      readAt: _dt(json['read_at']),
    );
  }

  InboxNotification copyWith({bool? isRead}) {
    return InboxNotification(
      uuid: uuid,
      displayId: displayId,
      patientId: patientId,
      type: type,
      typeLabel: typeLabel,
      priority: priority,
      status: isRead == true ? 'read' : status,
      isRead: isRead ?? this.isRead,
      title: title,
      body: body,
      deepLink: deepLink,
      sourceType: sourceType,
      sourceUuid: sourceUuid,
      createdAt: createdAt,
      sentAt: sentAt,
      readAt: readAt,
    );
  }

  static DateTime? _dt(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}
