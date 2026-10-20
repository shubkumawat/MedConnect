import 'package:get/get.dart';
import 'dart:async';

class AiPrescriptionController extends GetxController {
  var isUploading = false.obs;
  var isProcessing = false.obs;
  var scanResult = Rxn<Map<String, dynamic>>();
  var confidenceScore = 0.0.obs;

  Future<void> processImage() async {
    isUploading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isUploading.value = false;
    
    isProcessing.value = true;
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulated OCR Result
    scanResult.value = {
      'drug_names': ['Amoxicillin', 'Paracetamol', 'Cetirizine'],
      'dosage': ['500mg', '650mg', '10mg'],
      'frequency': ['TDS', 'BD', 'OD'],
      'duration': ['5 days', '3 days', '7 days'],
      'language': 'English/Hindi',
    };
    confidenceScore.value = 0.94;
    isProcessing.value = false;
  }

  void reset() {
    scanResult.value = null;
    isProcessing.value = false;
    isUploading.value = false;
  }
}
