import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class VisitRecording {
  final String id;
  final String path;
  final DateTime createdAt;
  final int durationMs;
  final String title;
  final String appointmentUuid;
  final String recordingUuid;
  final String transcript;
  final String status;

  VisitRecording({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.durationMs,
    this.title = 'Visit recording',
    this.appointmentUuid = '',
    this.recordingUuid = '',
    this.transcript = '',
    this.status = '',
  });

  String get durationLabel {
    final total = (durationMs / 1000).round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  VisitRecording copyWith({
    String? path,
    DateTime? createdAt,
    int? durationMs,
    String? title,
    String? appointmentUuid,
    String? recordingUuid,
    String? transcript,
    String? status,
  }) {
    return VisitRecording(
      id: id,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      title: title ?? this.title,
      appointmentUuid: appointmentUuid ?? this.appointmentUuid,
      recordingUuid: recordingUuid ?? this.recordingUuid,
      transcript: transcript ?? this.transcript,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'created_at': createdAt.toIso8601String(),
        'duration_ms': durationMs,
        'title': title,
        'appointment_uuid': appointmentUuid,
        'recording_uuid': recordingUuid,
        'transcript': transcript,
        'status': status,
      };

  factory VisitRecording.fromJson(Map<String, dynamic> json) {
    return VisitRecording(
      id: json['id']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      durationMs: int.tryParse(json['duration_ms']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? 'Visit recording',
      appointmentUuid: json['appointment_uuid']?.toString() ?? '',
      recordingUuid: json['recording_uuid']?.toString() ??
          json['uuid']?.toString() ??
          '',
      transcript: (json['transcript'] ??
              json['formatted_transcript'] ??
              json['raw_transcript'] ??
              '')
          .toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class VisitRecordingStore {
  static const _indexName = 'visit_recordings.json';

  Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/visit_recordings');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _indexFile() async {
    final dir = await _dir();
    return File('${dir.path}/$_indexName');
  }

  Future<List<VisitRecording>> load() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      final items = raw
          .whereType<Map>()
          .map((e) => VisitRecording.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<List<VisitRecording>> loadForAppointment(String appointmentUuid) async {
    final id = appointmentUuid.trim();
    if (id.isEmpty) return [];
    final all = await load();
    return all.where((e) => e.appointmentUuid == id).toList();
  }

  Future<void> _save(List<VisitRecording> items) async {
    final file = await _indexFile();
    await file.writeAsString(
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<String> nextFilePath() async {
    final dir = await _dir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return '${dir.path}/visit_$id.m4a';
  }

  Future<VisitRecording> add({
    required String path,
    required int durationMs,
    String title = 'Visit recording',
    String appointmentUuid = '',
    String recordingUuid = '',
    String transcript = '',
    String status = '',
  }) async {
    final items = await load();
    final rec = VisitRecording(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      createdAt: DateTime.now(),
      durationMs: durationMs,
      title: title,
      appointmentUuid: appointmentUuid,
      recordingUuid: recordingUuid,
      transcript: transcript,
      status: status,
    );
    items.insert(0, rec);
    await _save(items);
    return rec;
  }

  Future<VisitRecording> save(VisitRecording rec) async {
    final items = await load();
    final idx = items.indexWhere((e) => e.id == rec.id);
    if (idx >= 0) {
      items[idx] = rec;
    } else {
      items.insert(0, rec);
    }
    await _save(items);
    return rec;
  }

  Future<void> delete(VisitRecording rec) async {
    final items = await load();
    items.removeWhere((e) => e.id == rec.id);
    await _save(items);
    final file = File(rec.path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
