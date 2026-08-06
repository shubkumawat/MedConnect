import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/Util/Print/print_log.dart';
import '../../core/widgets/app_update_dialog.dart';

/// Checks whether a newer build is live on the Play Store / App Store and,
/// if so, surfaces [AppUpdateDialog].
///
/// Android goes through Google's Play Core "in_app_update" API — it only
/// reports real data for a build actually installed from the Play Store, so
/// debug/sideloaded builds simply see no update, silently.
/// iOS has no equivalent API, so it asks Apple's public iTunes Lookup
/// endpoint for the live version and compares it to the installed one.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String _bundleId = 'com.healaura.app';

  bool _checkedThisSession = false;

  /// Safe to call on every app launch (e.g. from the splash screen) — any
  /// failure (offline, store API down, not a store build) is swallowed so
  /// it never blocks the user from getting into the app.
  Future<void> checkForUpdate() async {
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    try {
      if (Platform.isAndroid) {
        await _checkAndroid();
      } else if (Platform.isIOS) {
        await _checkIOS();
      }
    } catch (e) {
      PrintLog.printLog('App update check failed: $e');
    }
  }

  Future<void> _checkAndroid() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

    _showDialog(
      onUpdate: () async {
        try {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
          } else {
            await _openStoreUrl(
                'https://play.google.com/store/apps/details?id=$_bundleId');
          }
        } catch (e) {
          PrintLog.printLog('In-app update failed, falling back to Play Store: $e');
          await _openStoreUrl(
              'https://play.google.com/store/apps/details?id=$_bundleId');
        }
      },
    );
  }

  Future<void> _checkIOS() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final response = await Dio().get(
      'https://itunes.apple.com/lookup',
      queryParameters: {'bundleId': _bundleId},
    );

    final results = response.data is Map ? response.data['results'] as List? : null;
    if (results == null || results.isEmpty) return;

    final store = results.first as Map;
    final storeVersion = store['version']?.toString();
    final storeUrl = store['trackViewUrl']?.toString() ??
        'https://apps.apple.com/app/id${store['trackId']}';
    if (storeVersion == null) return;

    if (_isNewer(storeVersion, packageInfo.version)) {
      _showDialog(
        currentVersion: packageInfo.version,
        latestVersion: storeVersion,
        onUpdate: () => _openStoreUrl(storeUrl),
      );
    }
  }

  Future<void> _openStoreUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Compares dotted version strings ("1.10.2" vs "1.9.0") numerically,
  /// segment by segment, so "1.10.0" correctly beats "1.9.0".
  bool _isNewer(String storeVersion, String currentVersion) {
    List<int> parse(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final store = parse(storeVersion);
    final current = parse(currentVersion);
    for (var i = 0; i < store.length || i < current.length; i++) {
      final s = i < store.length ? store[i] : 0;
      final c = i < current.length ? current[i] : 0;
      if (s != c) return s > c;
    }
    return false;
  }

  void _showDialog({
    String? currentVersion,
    String? latestVersion,
    required Future<void> Function() onUpdate,
  }) {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      AppUpdateDialog(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        onUpdate: onUpdate,
      ),
      barrierDismissible: true,
    );
  }
}
