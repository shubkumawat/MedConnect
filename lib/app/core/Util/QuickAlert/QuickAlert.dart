
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

class CustomQuickAlert {
  static void showQuickAlert({
    required String message,
    required String title,
    required QuickAlertType alertType,
    required BuildContext context,
  }) {
    QuickAlert.show(
      context: context,
      type: alertType, // Pass the alert type like QuickAlertType.info
      title: title,
      text: message,
      confirmBtnText: 'OK',
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // Close the alert when the user presses OK
      },
    );
  }
}
