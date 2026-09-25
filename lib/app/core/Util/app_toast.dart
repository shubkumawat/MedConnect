import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

/// App toasts wrap up to 3 lines so longer API messages stay readable.
class AppToast {
  static Future<bool?> showToast({
    required String msg,
    Toast toastLength = Toast.LENGTH_LONG,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int timeInSecForIosWeb = 4,
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 14,
  }) {
    final text = msg.trim();
    if (text.isEmpty) return Future.value(false);

    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (Get.overlayContext != null || Get.context != null) {
      Get.showSnackbar(
        GetSnackBar(
          messageText: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: fontSize,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: Duration(
            seconds: toastLength == Toast.LENGTH_SHORT ? 2 : timeInSecForIosWeb,
          ),
          snackPosition: gravity == ToastGravity.TOP
              ? SnackPosition.TOP
              : SnackPosition.BOTTOM,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          borderRadius: 12,
          backgroundColor: backgroundColor ?? const Color(0xE61B1B1B),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDismissible: true,
        ),
      );
      return Future.value(true);
    }

    return Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: gravity,
      timeInSecForIosWeb: timeInSecForIosWeb,
      backgroundColor: backgroundColor ?? const Color(0xE61B1B1B),
      textColor: textColor ?? Colors.white,
      fontSize: fontSize,
    );
  }
}
