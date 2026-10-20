import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../DataProvider/api_provider.dart';
import '../../../DataProvider/app_shared_preferences.dart';
import '../../../DataProvider/web_api_constant.dart';
import '../theme/app_colors.dart';
import 'web_page_helper.dart';
import 'CustomLoading/custom_loading.dart';
import '../../data/models/upcoming_appointment_model.dart';
import '../../data/services/storage_service.dart';
import '../../modules/records/controllers/records_controller.dart';
import '../../modules/records/views/appointment_detail_screen.dart';

class RecordingConsent {
  static Future<bool>? _inFlight;

  static Future<bool> isAllowed() async {
    final storage = StorageService();
    if (!await storage.getBool(StorageService.recordingConsentAsked)) {
      return false;
    }
    return storage.getBool(StorageService.recordingConsentAllowed);
  }

  static Future<bool> ensureAsked(BuildContext context, {String? patientId}) async {
    if (_inFlight != null) return _inFlight!;
    if (await isAllowed()) return true;
    if (!context.mounted) return false;
    _inFlight = showRecordingConsentDialog(context, patientId: patientId)
        .then((v) => v == true);
    try {
      return await _inFlight!;
    } finally {
      _inFlight = null;
    }
  }

  static Future<void> markAllowed({String? patientId}) async {
    if (await isAllowed()) return;
    final storage = StorageService();
    await storage.setBool(StorageService.recordingConsentAsked, true);
    await storage.setBool(StorageService.recordingConsentAllowed, true);
    unawaited(_postConsent('allow', patientId));
  }
}

Future<bool?> showRecordingConsentDialog(
  BuildContext context, {
  String? patientId,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.teal.withValues(alpha: 0.18),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.tealDark.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.tealDark,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Record this visit?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Healora can record the consultation and create a transcript for this appointment. You can stop anytime on the next screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                child: GestureDetector(
                  onTap: () => openWebPage(
                    title: 'Consultation audio',
                    url: WebApiConstant.WEB_CONSULTATION_AUDIO,
                  ),
                  child: const Text(
                    'Learn more about visit recording',
                    style: TextStyle(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _finishConsent(ctx, 'deny', patientId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: Color(0xFFE3EBE7)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Not now',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _finishConsent(ctx, 'allow', patientId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Start recording',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// First step on Record visit: Yes opens the recorder, No just closes.
Future<bool?> showStartVoiceRecordingDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.teal.withValues(alpha: 0.16),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.tealDark.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.tealDark,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Start voice recording?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Do you want to start recording this visit? Speak naturally — you can stop anytime on the next screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: Color(0xFFE3EBE7)),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'No',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _finishConsent(
  BuildContext ctx,
  String action,
  String? patientId,
) async {
  final allowed = action == 'allow';
  final storage = StorageService();
  await storage.setBool(StorageService.recordingConsentAsked, true);
  await storage.setBool(StorageService.recordingConsentAllowed, allowed);
  await CustomLoading().forceHide();
  if (ctx.mounted) {
    Navigator.of(ctx, rootNavigator: true).pop(allowed);
  }
  _postConsent(action, patientId);
}

Future<bool> _postConsent(String action, String? patientId) async {
  try {
    final token =
        await AppSharedPreferences().getString(AppSharedPreferences.token);
    final body = <String, dynamic>{'action': action};
    final pid = (patientId ?? '').trim();
    if (pid.isNotEmpty) body['patient_id'] = pid;
    final response = await ApiProvider().requestPostForApi(
      Get.context,
      WebApiConstant.API_URL_RECORDING_CONSENT,
      body,
      token ?? '',
    );
    final raw = response?.data;
    if (raw is Map && raw['error'] == true) return false;
    return response != null &&
        (response.statusCode == 200 || response.statusCode == 201);
  } catch (_) {
    return false;
  }
}

class AppointmentPrompts {
  static bool _busy = false;

  static Future<void> maybeShow({
    required List<UpcomingAppointment> upcoming,
    String? patientId,
  }) async {
    final live = upcoming.where((e) => e.isStillUpcoming).toList();
    if (_busy || live.isEmpty) return;
    final storage = StorageService();
    final loggedIn = await storage.getBool(StorageService.isLogin);
    final setupDone = await storage.getBool(StorageService.profileSetupDone);
    if (!loggedIn || !setupDone) return;

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null || !ctx.mounted) return;

    _busy = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final last = await storage.getString(StorageService.upcomingApptPopupDate);
      if (last != today) {
        await storage.setString(StorageService.upcomingApptPopupDate, today);
        if (ctx.mounted) {
          await showUpcomingAppointmentsDialog(ctx, live);
        }
      }
    } finally {
      _busy = false;
    }
  }
}

Future<void> showUpcomingAppointmentsDialog(
  BuildContext context,
  List<UpcomingAppointment> items,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7F5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.teal.withValues(alpha: 0.16),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.tealDark.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.tealDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Coming up',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items.length == 1
                                ? 'Today or tomorrow'
                                : '${items.length} visits · today & tomorrow',
                            style: TextStyle(
                              color: AppColors.textGray,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.48,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = items[i];
                    return UpcomingVisitCard(
                      appointment: a,
                      onTap: () {
                        Navigator.pop(ctx);
                        openUpcomingAppointment(a);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void openUpcomingAppointment(UpcomingAppointment a) {
  if (a.uuid.isEmpty) return;
  if (!Get.isRegistered<RecordsController>()) {
    Get.put(RecordsController());
  }
  Get.to(() => AppointmentDetailScreen(
        appointmentUuid: a.uuid,
        diseaseUuid: a.diseaseUuid,
        diseaseName: a.diseaseName.isEmpty ? 'Visit' : a.diseaseName,
      ));
}

class UpcomingVisitCard extends StatelessWidget {
  final UpcomingAppointment appointment;
  final VoidCallback? onTap;

  const UpcomingVisitCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final today = a.isToday;
    final accent = today ? AppColors.orange : AppColors.tealDark;
    final title = a.diseaseName.isEmpty ? a.kindLabel : a.diseaseName;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.08),
                Colors.white,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  today
                      ? Icons.today_rounded
                      : Icons.calendar_month_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        a.whenLabel,
                        a.kindLabel,
                        if (a.patientName.isNotEmpty) a.patientName,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.dayLabel.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
