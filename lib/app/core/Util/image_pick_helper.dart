import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';
import 'app_toast.dart';

/// Requests camera / gallery permission, then opens the picker.
class ImagePickHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pick({
    required ImageSource source,
    int imageQuality = 70,
  }) async {
    final allowed = await _ensurePermission(source);
    if (!allowed) return null;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      await _handlePickError(e, source);
      return null;
    }
  }

  /// Multi-image gallery pick (permission-safe, no unhandled crash).
  static Future<List<XFile>> pickMulti({
    int imageQuality = 70,
    int? limit,
  }) async {
    final allowed = await _ensurePermission(ImageSource.gallery);
    if (!allowed) return const [];

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        limit: limit,
      );
      return images;
    } catch (e) {
      await _handlePickError(e, ImageSource.gallery);
      return const [];
    }
  }

  static Future<void> _handlePickError(Object e, ImageSource source) async {
    final msg = e.toString();
    if (msg.contains('camera_access_denied') ||
        msg.contains('photo_access_denied') ||
        msg.contains('access_denied')) {
      await _showOpenSettingsDialog(
        source == ImageSource.camera ? 'Camera' : 'Photos',
      );
    } else {
      AppToast.showToast(msg: 'Could not pick image');
    }
  }

  static Permission _permissionFor(ImageSource source) {
    if (source == ImageSource.camera) return Permission.camera;
    if (Platform.isAndroid) return Permission.photos;
    return Permission.photos;
  }

  static Future<bool> _ensurePermission(ImageSource source) async {
    final permission = _permissionFor(source);
    final kind = source == ImageSource.camera ? 'Camera' : 'Photos';
    var status = await permission.status;

    // "While using the app" / Allow — already saved, do not prompt again.
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      await _showOpenSettingsDialog(kind);
      return false;
    }

    // Denied, or Android "Only this time" expired — ask again.
    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog(kind);
      return false;
    }

    AppToast.showToast(msg: '$kind permission is required');
    return false;
  }

  static Future<void> _showOpenSettingsDialog(String kind) async {
    final ctx = Get.context;
    if (ctx == null) {
      AppToast.showToast(
        msg: '$kind access denied. Enable it in Settings.',
      );
      return;
    }

    final go = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$kind permission needed',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '$kind access was denied. Please enable it in system Settings to continue.',
          style: const TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.tealDark),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (go == true) {
      await openAppSettings();
    }
  }
}
