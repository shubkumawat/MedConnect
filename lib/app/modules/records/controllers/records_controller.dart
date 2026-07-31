import 'package:dio/dio.dart' as dio;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/data/models/medical_record_model.dart';
import 'package:digitalhealth/app/data/models/disease_response_model.dart';
import 'package:digitalhealth/DataProvider/api_provider.dart';
import 'package:digitalhealth/DataProvider/app_shared_preferences.dart';
import 'package:digitalhealth/DataProvider/web_api_constant.dart';
import 'package:digitalhealth/app/modules/records/controllers/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../profile/controllers/profile_controller.dart';
import '../views/disease_pdf_preview_screen.dart';

class RecordsController extends GetxController {
  var diseases = <DiseaseResult>[].obs;
  var medications = <Medication>[].obs;
  var timelineEvents = <TimelineEvent>[].obs;
  var diseaseTimeline = <TimelineEvent>[].obs;
  var diseaseMedications = <Medication>[].obs;
  var diseaseDocuments = <Map<String, dynamic>>[].obs;
  var diseaseBills = <Map<String, dynamic>>[].obs;
  var isDocumentsLoading = false.obs;
  var isBillsLoading = false.obs;
  var selectedDisease = Rxn<DiseaseResult>();
  
  var isLoading = false.obs;
  var isTimelineLoading = false.obs;
  var timelineFilter = 0.obs;

  // Meta Data for Disease
  var conditionTypes = <Map<String, String>>[].obs;
  var statuses = <Map<String, String>>[].obs;
  var severities = <Map<String, String>>[].obs;
  var hereditaryOptions = <Map<String, String>>[].obs;
  var bodyPartsOptions = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchDiseases();
    fetchDiseaseMeta();
    fetchGlobalTimeline();
  }

  Future<void> fetchDiseaseMeta() async {
    try {
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_DISEASES_META,
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        if (data != null) {
          conditionTypes.value = (data['condition_types'] as List).map((e) => Map<String, String>.from(e)).toList();
          statuses.value = (data['statuses'] as List).map((e) => Map<String, String>.from(e)).toList();
          severities.value = (data['severities'] as List).map((e) => Map<String, String>.from(e)).toList();
          hereditaryOptions.value = (data['hereditary'] as List).map((e) => Map<String, String>.from(e)).toList();
          bodyPartsOptions.value = (data['body_parts'] as List).map((e) => Map<String, String>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease meta: $e");
    }
  }

  Future<void> fetchDiseases() async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var response = await ApiProvider().fetchDiseases(
        Get.context,
        WebApiConstant.API_URL_RECORDS_DISEASES,
        {},
        token ?? "",
      );

      if (response != null && response.error == false) {
        print("Response....${response.data!.results}");
        // DiseaseResponseModel model = DiseaseResponseModel.fromJson(response);
        if (response.data != null && response.data!.results != null) {
          diseases.value = response.data!.results!.toList();
        }
      }

    } catch (e) {
      debugPrint("Error fetching diseases: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDiseaseDetail(String uuid) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/",
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        print("details Response....$data");
        if (data != null) {
          selectedDisease.value = DiseaseResult.fromJson(data);
          // Fetch related data
          fetchDiseaseMedications(uuid);
          fetchDiseaseTimeline(uuid);
          fetchDiseaseDocuments(uuid);
          fetchDiseaseBills(uuid);
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease detail: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDiseaseMedications(String uuid) async {
    try {
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/medications/",
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        if (data != null && data['results'] != null) {
          diseaseMedications.value = (data['results'] as List)
              .map((e) => Medication.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease medications: $e");
    }
  }

  Future<void> fetchDiseaseTimeline(String uuid) async {
    try {
      isTimelineLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/timeline/",
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        print("details Response....$data");

        if (data != null && data['results'] != null) {
          diseaseTimeline.value = (data['results'] as List)
              .map((e) => TimelineEvent.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease timeline: $e");
    } finally {
      isTimelineLoading.value = false;
    }
  }

  Future<void> fetchDiseaseDocuments(String uuid) async {
    try {
      isDocumentsLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/documents/",
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        if (data != null && data['results'] != null) {
          diseaseDocuments.value = List<Map<String, dynamic>>.from(data['results']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease documents: $e");
    } finally {
      isDocumentsLoading.value = false;
    }
  }

  Future<void> fetchDiseaseBills(String uuid) async {
    try {
      isBillsLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/bills/",
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        if (data != null && data['results'] != null) {
          diseaseBills.value = List<Map<String, dynamic>>.from(data['results']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease bills: $e");
    } finally {
      isBillsLoading.value = false;
    }
  }

  Future<bool> uploadDiseaseDocument(String uuid, String filePath, String type) async {
    try {
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(filePath),
        'document_type': type, // 'slip' or 'bill'
      });

      var response = await ApiProvider().requestMultipartApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/documents/",
        formData,
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        if (type == 'slip') fetchDiseaseDocuments(uuid);
        else fetchDiseaseBills(uuid);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error uploading document: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> scanPrescription(String filePath, {String? diseaseUuid}) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(filePath),
      });

      if (diseaseUuid != null && diseaseUuid.isNotEmpty) {
        formData.fields.add(MapEntry('disease', diseaseUuid));
      } else {
        formData.fields.add(const MapEntry('new_disease_name', 'General Health'));
      }

      var response = await ApiProvider().requestMultipartApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_PRESCRIPTIONS,
        formData,
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        return response.data['data'] ?? response.data;
      }
      return null;
    } catch (e) {
      debugPrint("Error scanning prescription: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> reviewPrescription(String uuid, Map<String, dynamic> data, {String? diseaseUuid}) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      if (diseaseUuid != null && diseaseUuid.isNotEmpty) {
        data['disease'] = diseaseUuid;
      } else if (!data.containsKey('disease') && !data.containsKey('new_disease_name')) {
        data['new_disease_name'] = 'General Health';
      }

      var response = await ApiProvider().requestPostForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_PRESCRIPTIONS}$uuid/review/",
        data,
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        if (diseaseUuid != null) {
          fetchDiseaseDocuments(diseaseUuid);
          fetchDiseaseTimeline(diseaseUuid);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error confirming prescription: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDisease(String uuid) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var response = await ApiProvider().requestDeleteForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/",
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 204)) {
        diseases.removeWhere((element) => element.uuid == uuid);
        Get.back();
        Fluttertoast.showToast(msg: "Disease deleted successfully");
      }
    } catch (e) {
      debugPrint("Error deleting disease: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> archiveDisease(String uuid) async {
    try {
      isLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var response = await ApiProvider().requestPostForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/archive/",
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        fetchDiseases();
        Fluttertoast.showToast(msg: "Disease archived successfully");
      }
    } catch (e) {
      debugPrint("Error archiving disease: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<bool> addTimelineEvent({
    required String diseaseUuid,
    required String title,
    required String type,
    required String date,
    String? notes,
    String colorCode = "#008080",
  }) async {
    try {
      isTimelineLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      Map<String, dynamic> body = {
        "title": title,
        "event_type": type,
        "event_date": date,
        "notes": notes,
        "color_code": colorCode,
      };

      var response = await ApiProvider().requestPostForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$diseaseUuid/timeline/",
        body,
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        await fetchDiseaseTimeline(diseaseUuid);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding timeline event: $e");
      return false;
    } finally {
      isTimelineLoading(false);
    }
  }

  Future<void> exportDiseasePdf(String uuid) async {
    if (selectedDisease.value == null) {
      Fluttertoast.showToast(msg: "No disease data available to export");
      return;
    }

    try {
      isLoading.value = true;
      
      // Ensure ProfileController is available for the PDF report
      if (!Get.isRegistered<ProfileController>()) {
        Get.put(ProfileController());
      }

      Get.to(() => DiseasePdfPreviewScreen(
        disease: selectedDisease.value!,
        medications: diseaseMedications.toList(),
        timeline: diseaseTimeline.toList(),
      ));
    } catch (e) {
      debugPrint("Error generating PDF: $e");
      Fluttertoast.showToast(msg: "Error generating PDF");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchGlobalTimeline({String eventType = "", String disease = "", String dateFrom = "", String dateTo = ""}) async {
    try {
      isTimelineLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      Map<String, dynamic> query = {
        "event_type": eventType,
        "disease": disease,
        "date_from": dateFrom,
        "date_to": dateTo,
      };

      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.BASE_URL}health-records/timeline/",
        query,
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        if (data != null && data['results'] != null) {
          timelineEvents.value = (data['results'] as List)
              .map((e) => TimelineEvent.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching global timeline: $e");
    } finally {
      isTimelineLoading(false);
    }
  }

  Future<bool> addDisease({
    required String name,
    String icdCode = "",
    required String conditionType,
    required String status,
    required String severity,
    required String diagnosedOn,
    String? recoveredOn,
    List<String> bodyParts = const [],
    String hereditary = "no",
    String? nextFollowUpOn,
    bool hospitalizationRequired = false,
    String? admittedOn,
    String? dischargedOn,
    required String notes,
    String category = "",
  }) async {
    try {
      isLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      Map<String, dynamic> body = {
        "name": name,
        "icd_code": icdCode,
        "condition_type": conditionType,
        "status": status,
        "severity": severity,
        "diagnosed_on": diagnosedOn,
        "recovered_on": recoveredOn,
        "body_parts": bodyParts,
        "hereditary": hereditary,
        "next_follow_up_on": nextFollowUpOn,
        "hospitalization_required": hospitalizationRequired,
        "admitted_on": admittedOn,
        "discharged_on": dischargedOn,
        "notes": notes,
        "category": category,
      };

      var response = await ApiProvider().addDiseaseAPI(
        Get.context,
        WebApiConstant.API_URL_RECORDS_DISEASES,
        body,
        token ?? "",
      );

      if (response != null && response['error'] == false) {
        await fetchDiseases(); // Refresh the list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error adding disease: $e");
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateDisease({
    required String uuid,
    required String name,
    String icdCode = "",
    required String conditionType,
    required String status,
    required String severity,
    required String diagnosedOn,
    String? recoveredOn,
    List<String> bodyParts = const [],
    String hereditary = "no",
    String? nextFollowUpOn,
    bool hospitalizationRequired = false,
    String? admittedOn,
    String? dischargedOn,
    required String notes,
    String category = "",
  }) async {
    try {
      isLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      Map<String, dynamic> body = {
        "name": name,
        "icd_code": icdCode,
        "condition_type": conditionType,
        "status": status,
        "severity": severity,
        "diagnosed_on": diagnosedOn,
        "recovered_on": recoveredOn,
        "body_parts": bodyParts,
        "hereditary": hereditary,
        "next_follow_up_on": nextFollowUpOn,
        "hospitalization_required": hospitalizationRequired,
        "admitted_on": admittedOn,
        "discharged_on": dischargedOn,
        "notes": notes,
        "category": category,
      };

      var response = await ApiProvider().updateDiseaseAPI(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/",
        body,
        token ?? "",
      );

      if (response != null && response['error'] == false) {
        await fetchDiseases();
        if (selectedDisease.value?.uuid == uuid) {
          await fetchDiseaseDetail(uuid);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error updating disease: $e");
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRecords() async {
    await fetchDiseases();
  }

  void updateTimelineFilter(int index) {
    timelineFilter.value = index;
    String type = "";
    if (index == 1) type = "disease";
    else if (index == 2) type = "medication";
    else if (index == 3) type = "vaccine";
    else if (index == 4) type = "qr";
    
    fetchGlobalTimeline(eventType: type);
  }
}
