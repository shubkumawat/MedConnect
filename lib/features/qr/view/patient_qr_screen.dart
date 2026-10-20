import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/controller/home_controller.dart';
import '../controller/qr_controller.dart';

class PatientQRScreen extends GetView<QrController> {
  const PatientQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Patient QR"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Obx(() {
              final activePatient = homeController.activePatient.value;
              return Column(
                children: [
                  Text(
                    activePatient?.name ?? "Patient Name",
                    style: AppTextStyles.poppinsBold24.copyWith(color: Colors.white),
                  ),
                  Text(
                    "Blood Group: ${activePatient?.bloodGroup ?? 'N/A'}",
                    style: AppTextStyles.nunitoItalic14,
                  ),
                ],
              );
            }),
            const SizedBox(height: 30),
            Obx(() => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Opacity(
                            opacity: controller.isExpired.value ? 0.1 : 1.0,
                            child: const Icon(Icons.qr_code_2, size: 250, color: AppColors.primaryDeepBlue),
                          ),
                        ],
                      ),
                    ),
                    if (controller.isExpired.value)
                      Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          const Text(
                            "QR Expired",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: controller.regenerate,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
                            child: const Text("Regenerate", style: TextStyle(color: AppColors.primaryDeepBlue)),
                          ),
                        ],
                      ),
                  ],
                )),
            const SizedBox(height: 30),
            Obx(() {
              Color timerColor = Colors.white;
              if (controller.isCritical) timerColor = Colors.red;
              else if (controller.isWarning) timerColor = AppColors.warningOrange;

              return Column(
                children: [
                  Text("This QR code will expire in:", style: AppTextStyles.smallWhite70),
                  Text(
                    controller.timeString,
                    style: AppTextStyles.poppinsBold28.copyWith(color: timerColor),
                  ),
                ],
              );
            }),
            const SizedBox(height: 40),
            _buildScanLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Activity", style: AppTextStyles.poppinsBold18.copyWith(color: Colors.white)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDeepBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildLogItem("Dr. Sarah Smith", "2 mins ago", "City Hospital"),
              const Divider(color: Colors.white10, height: 1),
              _buildLogItem("Apollo Pharmacy", "1 hour ago", "Mumbai South"),
              const Divider(color: Colors.white10, height: 1),
              _buildLogItem("LifeLine Lab", "Yesterday", "Home Visit"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogItem(String user, String time, String location) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.accentTeal,
        child: Icon(Icons.person, color: AppColors.primaryDeepBlue, size: 20),
      ),
      title: Text(user, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text("$location • $time", style: const TextStyle(color: Colors.white60, fontSize: 12)),
      trailing: const Icon(Icons.check_circle_outline, color: AppColors.accentTeal, size: 18),
    );
  }
}
