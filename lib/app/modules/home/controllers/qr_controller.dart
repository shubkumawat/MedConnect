import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/qr_code_model.dart';
import 'package:healaura/app/core/Util/app_toast.dart';

class QrController extends GetxController {
  final String patientName;
  final String? patientId;
  final String? profilePhoto;
  final String? initials;
  /// True when QR is for the logged-in user (expire with `{}`).
  final bool isSelf;

  /// Default QR validity — also overridden by API `expiry_minutes`.
  static const int qrExpiryMinutes = 10;

  QrController({
    required this.patientName,
    this.patientId,
    this.profilePhoto,
    this.initials,
    this.isSelf = true,
  });

  final isLoading = false.obs;
  final isRegenerating = false.obs;
  final isDeleting = false.obs;
  final isSharing = false.obs;
  final qrData = Rxn<QrCodeData>();
  final secondsLeft = 0.obs;

  Timer? _timer;

  bool get isExpired => secondsLeft.value <= 0;

  int get activeExpiryMinutes =>
      qrData.value?.qr?.expiryMinutes ??
      qrData.value?.options?.defaultExpiryMinutes ??
      qrExpiryMinutes;

  Color get timerColor {
    if (isExpired) return const Color(0xFFE03A3A);
    if (secondsLeft.value <= 60) return const Color(0xFFE03A3A);
    if (secondsLeft.value <= 180) return const Color(0xFFE07B2A);
    return const Color(0xFF0A5C45);
  }

  double get progress {
    final total = activeExpiryMinutes * 60;
    if (total <= 0) return 0;
    return (secondsLeft.value / total).clamp(0.0, 1.0);
  }

  String get timerLabel {
    final m = secondsLeft.value ~/ 60;
    final s = secondsLeft.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get timerSubtitle {
    if (isExpired) return 'QR expired — generate a new one';
    if (secondsLeft.value <= 60) return 'Expiring soon';
    return 'Valid for $activeExpiryMinutes minutes';
  }

  String get lastScannedLabel {
    final raw = qrData.value?.lastScannedAt;
    if (raw == null || raw.isEmpty) return 'Not scanned yet';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return '${DateFormat('dd MMM yyyy').format(dt)} · ${DateFormat('h:mm a').format(dt)}';
  }

  String get expiresAtLabel {
    final raw = qrData.value?.qr?.expiresAt ?? qrData.value?.token?.expiresAt;
    if (raw == null) return '—';
    return DateFormat('h:mm a').format(raw.toLocal());
  }

  @override
  void onInit() {
    super.onInit();
    loadQr();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// Opens screen → call generate API for a fresh QR.
  Future<void> loadQr() async {
    try {
      isLoading.value = true;
      await generateQr(silent: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// "New QR" button — same generate API.
  Future<void> regenerateQr({bool silent = false}) =>
      generateQr(silent: silent);

  /// POST /qr-codes/expire/ — own: {} · family: { patient_id }
  Future<void> deleteQr() async {
    try {
      isDeleting.value = true;
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      // Own QR → empty body. Family QR → include patient_id.
      final body = <String, dynamic>{};
      if (!isSelf &&
          patientId != null &&
          patientId!.trim().isNotEmpty) {
        body['patient_id'] = patientId!.trim();
      }

      final response = await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_QR_EXPIRE,
        body,
        token,
      );

      final ok = response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204);
      final raw = response?.data;
      final apiError = raw is Map && raw['error'] == true;

      if (ok && !apiError) {
        _timer?.cancel();
        qrData.value = null;
        secondsLeft.value = 0;
        AppToast.showToast(
          msg: raw is Map
              ? (raw['message']?.toString() ?? 'QR deleted')
              : 'QR deleted',
        );
      } else {
        final msg = raw is Map ? raw['message']?.toString() : null;
        AppToast.showToast(msg: msg ?? 'Failed to delete QR');
      }
    } catch (e) {
      debugPrint('QR expire/delete error: $e');
      AppToast.showToast(msg: 'Failed to delete QR');
    } finally {
      isDeleting.value = false;
    }
  }

  /// POST /api/v1/qr-codes/generate/
  Future<void> generateQr({bool silent = false}) async {
    try {
      if (!silent) isRegenerating.value = true;
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      final body = <String, dynamic>{
        'expiry_minutes': qrExpiryMinutes,
      };
      if (patientId != null && patientId!.trim().isNotEmpty) {
        body['patient_id'] = patientId!.trim();
      }

      final response = await ApiProvider().requestPostForApi(
        Get.context,
        '${WebApiConstant.API_URL_QR_CODES}generate/',
        body,
        token,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map &&
          response.data['error'] != true) {
        _applyResponse(Map<String, dynamic>.from(response.data as Map));
        if (!silent) {
          AppToast.showToast(
            msg: response.data['message']?.toString() ??
                'QR generated successfully',
          );
        }
      } else {
        final msg = response?.data is Map
            ? response!.data['message']?.toString()
            : null;
        if (!silent) {
          AppToast.showToast(msg: msg ?? 'Failed to generate QR');
        }
      }
    } catch (e) {
      debugPrint('QR generate error: $e');
      if (!silent) {
        AppToast.showToast(msg: 'Failed to generate QR');
      }
    } finally {
      isRegenerating.value = false;
    }
  }

  void _applyResponse(Map<String, dynamic> json) {
    final parsed = QrCodeResponse.fromJson(json);
    qrData.value = parsed.data;

    final expiresAt =
        parsed.data?.qr?.expiresAt ?? parsed.data?.token?.expiresAt;
    _startCountdown(expiresAt);
  }

  void _startCountdown(DateTime? expiresAt) {
    _timer?.cancel();
    if (expiresAt == null) {
      final fallback =
          DateTime.now().add(Duration(minutes: activeExpiryMinutes));
      _startCountdown(fallback);
      return;
    }
    void tick() {
      final diff = expiresAt.toLocal().difference(DateTime.now()).inSeconds;
      secondsLeft.value = diff > 0 ? diff : 0;
      if (secondsLeft.value <= 0) _timer?.cancel();
    }

    tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> shareQr() async {
    if (isExpired) {
      AppToast.showToast(msg: 'This QR has expired. Generate a new one to share.');
      return;
    }
    final qr = qrData.value?.qr;
    final imageUrl = qr?.resolvedImageUrl;
    final scanUrl = (qr?.scanUrl ?? qr?.payloadUrl ?? '').trim();
    final text =
        "${patientName}'s Healora Health QR — valid for $activeExpiryMinutes minutes"
        "${scanUrl.isNotEmpty ? '\n$scanUrl' : ''}";

    if ((imageUrl == null || imageUrl.isEmpty) && scanUrl.isEmpty) {
      AppToast.showToast(msg: 'QR is not available to share yet');
      return;
    }

    try {
      isSharing.value = true;
      Rect? origin;
      final box = Get.context?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final response = await dio.Dio().get<List<int>>(
          imageUrl,
          options: dio.Options(responseType: dio.ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(response.data ?? []);
        if (bytes.isNotEmpty) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/healora_health_qr.png');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'image/png', name: 'Healora_Health_QR.png')],
            text: text,
            sharePositionOrigin: origin,
          );
          return;
        }
      }

      if (scanUrl.isNotEmpty) {
        await Share.share(text, sharePositionOrigin: origin);
        return;
      }
      AppToast.showToast(msg: 'Could not download QR image');
    } catch (e) {
      debugPrint('Share QR error: $e');
      AppToast.showToast(msg: 'Failed to share QR');
    } finally {
      isSharing.value = false;
    }
  }
}
