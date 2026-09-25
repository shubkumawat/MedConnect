import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/services/visit_recording_store.dart';
import '../../../core/Util/appointment_prompts.dart';
import '../controllers/records_controller.dart';
import 'appointment_transcript_screen.dart';
import 'appointment_record_screen.dart';

class AppointmentRecordingCard extends StatefulWidget {
  final String appointmentUuid;

  const AppointmentRecordingCard({super.key, required this.appointmentUuid});

  @override
  State<AppointmentRecordingCard> createState() =>
      _AppointmentRecordingCardState();
}

class _AppointmentRecordingCardState extends State<AppointmentRecordingCard> {
  final _store = VisitRecordingStore();
  final _player = AudioPlayer();
  final RecordsController _records = Get.find<RecordsController>();

  List<VisitRecording> _items = [];
  bool _loading = true;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _reload();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final local = await _store.loadForAppointment(widget.appointmentUuid);
    if (!mounted) return;
    setState(() {
      _items = local;
      _loading = false;
    });
    unawaited(_syncRemote().then((_) {
      for (final rec in List<VisitRecording>.from(_items)) {
        if (rec.recordingUuid.isNotEmpty && rec.transcript.trim().isEmpty) {
          unawaited(_pollInBackground(rec));
        }
      }
    }));
  }

  Future<void> _syncRemote() async {
    final remote =
        await _records.fetchConsultationRecordings(widget.appointmentUuid);
    if (remote.isEmpty || !mounted) return;
    var items = List<VisitRecording>.from(_items);
    for (final row in remote) {
      final uuid = (row['uuid'] ?? row['recording_uuid'] ?? '').toString();
      if (uuid.isEmpty) continue;
      final text = (row['formatted_transcript'] ??
              row['transcript'] ??
              row['raw_transcript'] ??
              '')
          .toString();
      final status = (row['status'] ?? '').toString();
      final display = (row['display_id'] ?? 'Visit recording').toString();
      final idx = items.indexWhere((e) => e.recordingUuid == uuid);
      if (idx >= 0) {
        items[idx] = items[idx].copyWith(
          transcript: text.isNotEmpty ? text : items[idx].transcript,
          status: status.isNotEmpty ? status : items[idx].status,
          title: display,
        );
        await _store.save(items[idx]);
      } else {
        final rec = VisitRecording(
          id: uuid,
          path: '',
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
              DateTime.now(),
          durationMs: 0,
          title: display,
          appointmentUuid: widget.appointmentUuid,
          recordingUuid: uuid,
          transcript: text,
          status: status,
        );
        items.insert(0, rec);
        await _store.save(rec);
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _pollInBackground(VisitRecording rec) async {
    if (rec.recordingUuid.isEmpty) return;
    final transcript =
        await _records.pollConsultationTranscript(rec.recordingUuid);
    if (transcript != null) {
      await _applyTranscript(rec, transcript);
    }
  }

  Future<void> _applyTranscript(
      VisitRecording rec, Map<String, dynamic> data) async {
    final text = (data['formatted_transcript'] ??
            data['transcript'] ??
            data['raw_transcript'] ??
            '')
        .toString();
    final status = (data['status'] ?? rec.status).toString();
    final updated = rec.copyWith(transcript: text, status: status);
    await _store.save(updated);
    if (!mounted) return;
    setState(() {
      _items = _items
          .map((e) => e.id == rec.id ? updated : e)
          .toList();
    });
  }

  Future<void> _onRecordTap() async {
    final start = await showStartVoiceRecordingDialog(context);
    if (start != true || !mounted) return;
    await RecordingConsent.markAllowed(
      patientId: _records.selectedPatientId.value,
    );
    if (!mounted) return;
    final saved = await Get.to<bool>(
      () => AppointmentRecordScreen(
        appointmentUuid: widget.appointmentUuid,
      ),
    );
    if (saved == true) {
      await _reload();
    }
  }

  Future<void> _play(VisitRecording rec) async {
    if (rec.path.isEmpty || !File(rec.path).existsSync()) return;
    if (_playingId == rec.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    await _player.stop();
    await _player.play(DeviceFileSource(rec.path));
    setState(() => _playingId = rec.id);
  }

  String _statusLabel(VisitRecording rec) {
    final s = rec.status.toLowerCase();
    if (s == 'completed') return 'Transcript ready';
    if (s == 'processing' || s == 'uploading') return 'Transcribing…';
    if (s == 'upload_failed' || s == 'failed' || s == 'error') {
      return 'Could not transcribe';
    }
    if (rec.transcript.trim().isNotEmpty) return 'Transcript ready';
    return rec.status.isEmpty ? '' : rec.status;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3EBE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit recording',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record this appointment. Transcript appears here after upload.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _onRecordTap,
                icon: const Icon(Icons.mic_rounded),
                label: const Text(
                  'Record visit',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No recording for this visit yet.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                ),
              )
            else
              ..._items.map((rec) {
                final playing = _playingId == rec.id;
                final hasFile =
                    rec.path.isNotEmpty && File(rec.path).existsSync();
                final text = rec.transcript.trim();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hasFile)
                              IconButton(
                                onPressed: () => _play(rec),
                                icon: Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: AppColors.tealDark,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    [
                                      DateFormat('d MMM yyyy, hh:mm a')
                                          .format(rec.createdAt),
                                      if (rec.durationMs > 0) rec.durationLabel,
                                      _statusLabel(rec),
                                    ].where((e) => e.isNotEmpty).join(' · '),
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textGray),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => Get.to(() => AppointmentTranscriptScreen(
                                  title: rec.title,
                                  transcript: text,
                                  subtitle: DateFormat('d MMM yyyy, hh:mm a')
                                      .format(rec.createdAt),
                                )),
                            child: const Text(
                              'Read more',
                              style: TextStyle(
                                color: AppColors.tealDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
