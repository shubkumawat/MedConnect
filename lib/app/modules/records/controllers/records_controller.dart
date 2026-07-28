import 'package:get/get.dart';
import 'package:digitalhealth/app/data/models/medical_record_model.dart';
import 'package:digitalhealth/DataProvider/api_provider.dart';
import 'package:digitalhealth/DataProvider/app_shared_preferences.dart';
import 'package:flutter/material.dart';

class RecordsController extends GetxController {
  var diseases = <MedicalRecord>[].obs;
  var medications = <Medication>[].obs;
  var timelineEvents = <TimelineEvent>[].obs;
  
  var isLoading = false.obs;
  var timelineFilter = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    try {
      isLoading(true);
      // Simulating API calls for now as endpoints might be in flux
      // String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      // Mock data until API is ready
      await Future.delayed(const Duration(seconds: 1));
      
      diseases.value = [
        MedicalRecord(id: '1', name: 'Hernia (Inguinal)', status: 'Active', diagnosedDate: 'Jan 2023', doctorName: 'Dr. Sharma', type: 'disease'),
        MedicalRecord(id: '2', name: 'Type 2 Diabetes', status: 'Monitoring', diagnosedDate: 'Mar 2022', doctorName: 'Dr. Gupta', type: 'disease'),
        MedicalRecord(id: '3', name: 'Hypertension', status: 'Active', diagnosedDate: 'Jun 2021', doctorName: 'Dr. Mehra', type: 'disease'),
      ];

      medications.value = [
        Medication(id: '1', name: 'Metformin 500mg', frequency: 'Twice daily', timing: 'After Food', diseaseName: 'Type 2 Diabetes'),
        Medication(id: '2', name: 'Amlodipine 5mg', frequency: 'Once daily', timing: 'Morning', diseaseName: 'Hypertension'),
      ];

      timelineEvents.value = [
        TimelineEvent(id: '1', title: 'Metformin taken — 8:00 AM', time: 'Today 8:00', type: 'med', colorCode: '#FF9800'),
        TimelineEvent(id: '2', title: 'QR scanned — Dr. Gupta', time: 'Today 3:15', type: 'qr', colorCode: '#008080'),
      ];

    } finally {
      isLoading(false);
    }
  }

  void updateTimelineFilter(int index) {
    timelineFilter.value = index;
    // Implement filtering logic here
  }
}
