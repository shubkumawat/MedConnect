import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/ai_prescription_controller.dart';

class AiPrescriptionReaderScreen extends GetView<AiPrescriptionController> {
  const AiPrescriptionReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text("AI Prescription Reader"),
      ),
      body: Obx(() {
        if (controller.isUploading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accentTeal));
        }
        if (controller.isProcessing.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.accentTeal),
                const SizedBox(height: 20),
                Text("AI is analyzing your prescription...", style: AppTextStyles.poppinsMedium16),
                Text("Supports Hindi & English", style: AppTextStyles.nunitoItalic14),
              ],
            ),
          );
        }

        if (controller.scanResult.value != null) {
          return _buildResultView();
        }

        return _buildUploadView();
      }),
    );
  }

  Widget _buildUploadView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: controller.processImage,
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primaryDeepBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accentTeal, style: BorderStyle.solid, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 80, color: AppColors.accentTeal),
                  const SizedBox(height: 20),
                  Text("Tap to upload prescription", style: AppTextStyles.poppinsBold18.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text("JPG, PNG or PDF", style: AppTextStyles.smallWhite70),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Our AI will extract drug names, dosages, and instructions automatically.",
            textAlign: TextAlign.center,
            style: AppTextStyles.poppinsMedium16.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = controller.scanResult.value!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentTeal),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.accentTeal),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Analysis Complete", style: AppTextStyles.poppinsBold18.copyWith(color: AppColors.accentTeal, fontSize: 16)),
                    Text("Confidence Score: ${(controller.confidenceScore.value * 100).toInt()}%", style: AppTextStyles.smallWhite70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text("Extracted Medications", style: AppTextStyles.poppinsBold18.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          ...List.generate(result['drug_names'].length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryDeepBlue, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const CircleAvatar(backgroundColor: AppColors.accentTeal, child: Icon(Icons.medication, color: AppColors.primaryDeepBlue)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result['drug_names'][index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("${result['dosage'][index]} - ${result['frequency'][index]} (${result['duration'][index]})", 
                             style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: controller.reset,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Save to Records", style: TextStyle(color: AppColors.primaryDeepBlue, fontWeight: FontWeight.bold)),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: controller.reset,
              child: const Text("Discard", style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ],
      ),
    );
  }
}
