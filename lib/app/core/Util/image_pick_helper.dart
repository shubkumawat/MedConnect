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

    // Gallery: always re-ask. Android "Only this time" still reports granted
    // until the process dies, so skipping request() looks like a permanent allow.
    if (source == ImageSource.gallery) {
      final proceed = await _confirmGalleryAccess();
      if (!proceed) return false;
      var galleryStatus = await permission.request();
      if (galleryStatus.isGranted || galleryStatus.isLimited) return true;
      if (galleryStatus.isPermanentlyDenied || galleryStatus.isRestricted) {
        await _showOpenSettingsDialog(kind);
        return false;
      }
      AppToast.showToast(msg: '$kind permission is required');
      return false;
    }

    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      await _showOpenSettingsDialog(kind);
      return false;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      await _showOpenSettingsDialog(kind);
      return false;
    }

    AppToast.showToast(msg: '$kind permission is required');
    return false;
  }

  /// In-app prompt every gallery pick (change / delete / new photo).
  static Future<bool> _confirmGalleryAccess() async {
    final ctx = Get.context;
    if (ctx == null) return true;

    final go = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Photos access',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Healora needs access to your photos to set or change your profile picture. You can allow it this time only from the next system prompt.',
          style: TextStyle(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.tealDark),
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return go == true;
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
