import 'package:flutter/material.dart';

enum TimelineEventType {
  diseaseDiagnosed,
  medicationAdded,
  prescriptionUploaded,
  doctorVisit,
  vaccination,
  labReport,
  qrScanned,
  accessGranted,
  manualNote
}

class TimelineEventModel {
  String id;
  TimelineEventType type;
  DateTime timestamp;
  String title;
  String description;
  String? thumbnail;
  Map<String, dynamic>? metadata;

  TimelineEventModel({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    this.thumbnail,
    this.metadata,
  });

  IconData get icon {
    switch (type) {
      case TimelineEventType.diseaseDiagnosed: return Icons.biotech;
      case TimelineEventType.medicationAdded: return Icons.medication;
      case TimelineEventType.prescriptionUploaded: return Icons.receipt_long;
      case TimelineEventType.doctorVisit: return Icons.person;
      case TimelineEventType.vaccination: return Icons.vaccines;
      case TimelineEventType.labReport: return Icons.science;
      case TimelineEventType.qrScanned: return Icons.qr_code_scanner;
      case TimelineEventType.accessGranted: return Icons.lock_open;
      case TimelineEventType.manualNote: return Icons.note;
    }
  }

  Color get color {
    switch (type) {
      case TimelineEventType.diseaseDiagnosed: return Colors.redAccent;
      case TimelineEventType.medicationAdded: return Colors.blueAccent;
      case TimelineEventType.prescriptionUploaded: return Colors.orangeAccent;
      case TimelineEventType.doctorVisit: return Colors.purpleAccent;
      case TimelineEventType.vaccination: return Colors.greenAccent;
      case TimelineEventType.labReport: return Colors.tealAccent;
      case TimelineEventType.qrScanned: return Colors.amberAccent;
      case TimelineEventType.accessGranted: return Colors.cyanAccent;
      case TimelineEventType.manualNote: return Colors.grey;
    }
  }
}
