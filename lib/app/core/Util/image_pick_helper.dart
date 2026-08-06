import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';


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
      final msg = e.toString();
      if (msg.contains('camera_access_denied') ||
          msg.contains('photo_access_denied')) {
        await _showOpenSettingsDialog(
          source == ImageSource.camera ? 'Camera' : 'Photos',
        );
      } else {
        Fluttertoast.showToast(msg: 'Could not pick image');
      }
      return null;
    }
  }

  static Future<bool> _ensurePermission(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;

    var status = await permission.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (status.isPermanentlyDenied || status.isDenied || status.isRestricted) {
      await _showOpenSettingsDialog(
        source == ImageSource.camera ? 'Camera' : 'Photos',
      );
      return false;
    }

    Fluttertoast.showToast(
      msg: source == ImageSource.camera
          ? 'Camera permission is required'
          : 'Photos permission is required',
    );
    return false;
  }

  static Future<void> _showOpenSettingsDialog(String kind) async {
    final ctx = Get.context;
    if (ctx == null) {
      Fluttertoast.showToast(
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
