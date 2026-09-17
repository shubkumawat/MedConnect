import 'dart:math';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

bool isDialogShoing = false;
BuildContext? contexDialog;

class CustomLoading {
  static final CustomLoading _singleton = CustomLoading._internal();

  factory CustomLoading() {
    return _singleton;
  }
  String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();
  CustomLoading._internal();

  Future<bool> show(BuildContext? context) async {
    try {
      if (isDialogShoing) return true;
      final ctx = context;
      if (ctx == null) return true;
      isDialogShoing = true;
      showDialog(
        context: ctx,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (BuildContext dialogContext) {
          contexDialog = dialogContext;
          return PopScope(
            canPop: false,
            child: Dialog(
              key: Key(getRandomString(10)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              insetPadding: const EdgeInsets.all(20),
              backgroundColor: Colors.transparent,
              child: LoaderTransparent(),
            ),
          );
        },
      );
      return true;
    } catch (_) {
      isDialogShoing = false;
      return true;
    }
  }

  Future<bool> forceHide() {
    isDialogShoing = true;
    return hide(null);
  }

  Future<bool> hide(BuildContext? context) async {
    try {
      if (!isDialogShoing && contexDialog == null) return true;
      isDialogShoing = false;
      final dialogCtx = contexDialog;
      contexDialog = null;
      if (dialogCtx != null && dialogCtx.mounted) {
        final nav = Navigator.of(dialogCtx, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
      return true;
    } catch (_) {
      isDialogShoing = false;
      contexDialog = null;
      return true;
    }
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}

class LoaderTransparent extends StatelessWidget {
  double height = 60.00;
  double width = 60.00;
  LoaderTransparent({super.key});

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: height,
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
