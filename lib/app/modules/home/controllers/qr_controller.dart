import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/qr_code_model.dart';

class QrController extends GetxController {
  final String patientName;
  final String? patientId;
  final String? profilePhoto;
  final String? initials;

  /// Health QR is always valid for 10 minutes.
  static const int qrExpiryMinutes = 10;

  QrController({
    required this.patientName,
    this.patientId,
    this.profilePhoto,
    this.initials,
  });

  final isLoading = false.obs;
  final isRegenerating = false.obs;
  final qrData = Rxn<QrCodeData>();
  final secondsLeft = 0.obs;

  Timer? _timer;

  bool get isExpired => secondsLeft.value <= 0;

  Color get timerColor {
    if (isExpired) return const Color(0xFFE03A3A);
    if (secondsLeft.value <= 60) return const Color(0xFFE03A3A);
    if (secondsLeft.value <= 180) return const Color(0xFFE07B2A);
    return const Color(0xFF0A5C45);
  }

  double get progress {
    final total = qrExpiryMinutes * 60;
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
    return 'Valid for $qrExpiryMinutes minutes';
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

  Future<void> loadQr() async {
    try {
      isLoading.value = true;
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      final response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_QR_CURRENT,
        {
          if (patientId != null && patientId!.trim().isNotEmpty)
            'patient_id': patientId!.trim(),
        },
        token ?? '',
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data is Map &&
          response.data['error'] != true) {
        _applyResponse(Map<String, dynamic>.from(response.data));
        // Always refresh to a fresh 10‑minute QR if current is expired/missing.
        if (isExpired || qrData.value?.qr?.resolvedImageUrl == null) {
          await regenerateQr(silent: true);
        }
      } else {
        await regenerateQr(silent: true);
      }
    } catch (e) {
      debugPrint('QR load error: $e');
      await regenerateQr(silent: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> regenerateQr({bool silent = false}) async {
    try {
      if (!silent) isRegenerating.value = true;
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      final body = <String, dynamic>{
        'expiry_minutes': qrExpiryMinutes,
      };
      if (patientId != null && patientId!.isNotEmpty) {
        body['patient_id'] = patientId;
      }

      final response = await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_QR_REGENERATE,
        body,
        token ?? '',
      );

      if (response != null &&
          response.data is Map &&
          response.data['error'] != true) {
        _applyResponse(Map<String, dynamic>.from(response.data));
        if (!silent) {
          Fluttertoast.showToast(
            msg: response.data['message']?.toString() ??
                'New QR generated (valid 10 min)',
          );
        }
      } else {
        final msg = response?.data is Map
            ? response!.data['message']?.toString()
            : null;
        Fluttertoast.showToast(msg: msg ?? 'Failed to regenerate QR');
      }
    } catch (e) {
      debugPrint('QR regenerate error: $e');
      Fluttertoast.showToast(msg: 'Failed to regenerate QR');
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
      // Fallback: 10 minutes from now if API omitted expiry.
      final fallback = DateTime.now().add(const Duration(minutes: qrExpiryMinutes));
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
    final imageUrl = qrData.value?.qr?.resolvedImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      Fluttertoast.showToast(msg: 'QR image not available to share');
      return;
    }

    try {
      isLoading.value = true;
      final response = await dio.Dio().get<List<int>>(
        imageUrl,
        options: dio.Options(responseType: dio.ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data ?? []);
      if (bytes.isEmpty) {
        Fluttertoast.showToast(msg: 'Could not download QR image');
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/healaura_health_qr.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            "${patientName}'s HealAura Health QR — valid for $qrExpiryMinutes minutes",
      );
    } catch (e) {
      debugPrint('Share QR error: $e');
      Fluttertoast.showToast(msg: 'Failed to share QR');
    } finally {
      isLoading.value = false;
    }
  }
}
