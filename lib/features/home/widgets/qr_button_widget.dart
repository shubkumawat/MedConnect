import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';

import '../../qr/view/patient_qr_screen.dart';

class QRButtonWidget extends StatelessWidget {
  const QRButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.qr_code_scanner, color: AppColors.accentTeal, size: 30),
      onPressed: () {
        Get.to(() => const PatientQRScreen());
      },
    );
  }
}
