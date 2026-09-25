import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/services/visit_recording_store.dart';
import '../controllers/records_controller.dart';
import 'package:healora/app/core/Util/app_toast.dart';

/// Full-screen visit recorder. Minimum 5 seconds before stop is allowed.
class AppointmentRecordScreen extends StatefulWidget {
  final String appointmentUuid;

  const AppointmentRecordScreen({super.key, required this.appointmentUuid});

  @override
  State<AppointmentRecordScreen> createState() =>
      _AppointmentRecordScreenState();
}

class _AppointmentRecordScreenState extends State<AppointmentRecordScreen>
    with SingleTickerProviderStateMixin {
  static const _minSeconds = 5;

  final _store = VisitRecordingStore();
  final _recorder = AudioRecorder();
  final RecordsController _records = Get.find<RecordsController>();

  late final AnimationController _pulse;
  Timer? _tick;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  String? _path;
  bool _starting = true;
  bool _stopping = false;
  bool _failed = false;

  bool get _canStop => _elapsed.inSeconds >= _minSeconds;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<bool> _ensureMic() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    status = await Permission.microphone.request();
    if (status.isGranted) return true;
    AppToast.showToast(
      msg: status.isPermanentlyDenied
          ? 'Enable microphone in Settings to record this visit.'
          : 'Microphone permission is needed to record.',
    );
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return false;
  }

  Future<void> _start() async {
    if (!await _ensureMic()) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    try {
      final path = await _store.nextFilePath();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _path = path;
      _startedAt = DateTime.now();
      _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final start = _startedAt;
        if (start == null || !mounted) return;
        setState(() => _elapsed = DateTime.now().difference(start));
      });
      if (mounted) setState(() => _starting = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _failed = true;
        });
      }
      AppToast.showToast(msg: 'Could not start recording.');
    }
  }

  Future<void> _stopAndSave() async {
    if (_stopping) return;
    if (!_canStop) {
      AppToast.showToast(
        msg: 'Record at least $_minSeconds seconds before stopping.',
      );
      return;
    }
    setState(() => _stopping = true);
    _tick?.cancel();
    try {
      final path = await _recorder.stop() ?? _path;
      final duration = _elapsed;
      if (path == null || path.isEmpty || !File(path).existsSync()) {
        if (mounted) Navigator.pop(context, false);
        return;
      }
      var rec = await _store.add(
        path: path,
        durationMs: duration.inMilliseconds,
        appointmentUuid: widget.appointmentUuid,
        status: 'uploading',
        title:
            'Visit · ${DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now())}',
      );
      final uploaded = await _records.uploadConsultationRecording(
        appointmentUuid: widget.appointmentUuid,
        filePath: path,
      );
      if (uploaded == null) {
        rec = rec.copyWith(status: 'upload_failed');
        await _store.save(rec);
        AppToast.showToast(msg: 'Recording saved. Upload will retry later.');
        if (mounted) Navigator.pop(context, true);
        return;
      }
      rec = rec.copyWith(
        recordingUuid: (uploaded['uuid'] ?? '').toString(),
        status: (uploaded['status'] ?? 'processing').toString(),
        title: (uploaded['display_id'] ?? rec.title).toString(),
      );
      await _store.save(rec);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      AppToast.showToast(msg: 'Could not save recording.');
      if (mounted) setState(() => _stopping = false);
    }
  }

  Future<void> _discard() async {
    if (_stopping) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Discard recording?'),
        content: const Text(
          'This visit recording will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep recording'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.statusRed),
            ),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _tick?.cancel();
    try {
      await _recorder.stop();
    } catch (_) {}
    final path = _path;
    if (path != null && File(path).existsSync()) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context, false);
  }

  String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final remain = math.max(0, _minSeconds - _elapsed.inSeconds);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07271E),
        body: Stack(
          children: [
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentTeal.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, top > 0 ? 8 : 16, 20, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _stopping ? null : _discard,
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Visit recording',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, _) {
                        final t = _pulse.value;
                        return SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _ring(1.0 + t * 0.35, 0.10 * (1 - t)),
                              _ring(0.82 + t * 0.22, 0.16 * (1 - t * 0.6)),
                              Container(
                                width: 128,
                                height: 128,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.statusRed,
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _clock(_elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.statusRed.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _starting
                            ? 'Starting…'
                            : _stopping
                                ? 'Saving recording…'
                                : _failed
                                    ? 'Could not record'
                                    : 'Recording in progress',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _canStop
                          ? 'Tap stop when the consultation is done'
                          : 'Keep going · ${remain}s more required',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (_starting || _stopping || _failed)
                            ? null
                            : _stopAndSave,
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(
                          _canStop ? 'Stop & save' : 'Stop (min ${_minSeconds}s)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.tealDark,
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.35),
                          disabledForegroundColor: Colors.white70,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
            width: 2,
          ),
        ),
      ),
    );
  }
}
