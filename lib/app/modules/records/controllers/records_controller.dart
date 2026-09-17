import 'package:healaura/app/data/services/storage_service.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import 'package:healaura/app/data/models/appointment_model.dart';
import 'package:healaura/app/data/models/disease_response_model.dart';
import 'package:healaura/app/data/models/disease_document_model.dart';
import 'package:healaura/app/data/models/family_member_model.dart';
import 'package:healaura/DataProvider/api_provider.dart';
import 'package:healaura/DataProvider/app_shared_preferences.dart';
import 'package:healaura/DataProvider/web_api_constant.dart';
import 'package:healaura/app/modules/records/controllers/pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../views/disease_pdf_preview_screen.dart';
import 'package:healaura/app/core/Util/app_toast.dart';

class RecordsController extends GetxController {
  var diseases = <DiseaseResult>[].obs;
  var medications = <Medication>[].obs;
  var timelineEvents = <TimelineEvent>[].obs;
  var diseaseTimeline = <TimelineEvent>[].obs;
  var diseaseMedications = <Medication>[].obs;
  var selectedMedication = Rxn<Medication>();
  var diseaseDocuments = <DiseaseDocument>[].obs;
  var diseaseBills = <Map<String, dynamic>>[].obs;
  var isDocumentsLoading = false.obs;
  var isBillsLoading = false.obs;
  var isDocumentUploading = false.obs;
  var isMedicationsLoading = false.obs;
  var isCurrentMedicationsLoading = false.obs;
  var isMedicationDetailLoading = false.obs;
  var medicineSearchResults = <Map<String, dynamic>>[].obs;
  var selectedDisease = Rxn<DiseaseResult>();
  var diseaseAppointments = <DiseaseAppointment>[].obs;
  var selectedAppointment = Rxn<AppointmentDetail>();
  var isAppointmentsLoading = false.obs;
  var isAppointmentDetailLoading = false.obs;

  /// Active Health Passport member — records APIs send this `patient_id`.
  final selectedPatientId = ''.obs;
  final selectedPatientName = 'Patient'.obs;
  final selectedPatientRelation = 'Me'.obs;
  final selectedPatientPhoto = ''.obs;
  final selectedIsSelf = true.obs;

  /// '' | prescription | report
  var documentTypeFilter = 'prescription'.obs;
  var documentTypes = <DocumentTypeOption>[].obs;
  var reportTypes = <ReportTypeInfo>[].obs;
  
  var isLoading = false.obs;
  var isTimelineLoading = false.obs;
  var timelineFilter = 0.obs;

  // Meta Data for Disease
  var conditionTypes = <Map<String, String>>[].obs;
  var statuses = <Map<String, String>>[].obs;
  var severities = <Map<String, String>>[].obs;
  var hereditaryOptions = <Map<String, String>>[].obs;
  var bodyPartsOptions = <Map<String, String>>[].obs;

  Map<String, dynamic> patientQuery([Map<String, dynamic>? extra]) {
    final q = <String, dynamic>{if (extra != null) ...extra};
    final id = selectedPatientId.value.trim();
    if (id.isNotEmpty) q['patient_id'] = id;
    return q;
  }

  void attachPatientId(Map<String, dynamic> body) {
    final id = selectedPatientId.value.trim();
    if (id.isNotEmpty) body['patient_id'] = id;
  }

  void attachAppointmentUuid(Map<String, dynamic> body, String? appointmentUuid) {
    final id = appointmentUuid?.trim() ?? '';
    if (id.isNotEmpty) body['appointment_uuid'] = id;
  }

  String _apiMessage(dynamic raw, {String fallback = 'Something went wrong'}) {
    if (raw is Map) {
      final msg = raw['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
      final data = raw['data'];
      if (data is List && data.isNotEmpty) return data.first.toString();
      if (data is String && data.trim().isNotEmpty) return data.trim();
    }
    return fallback;
  }

  void applySelectedMember(FamilyMember p) => _applySelectedMember(p);

  void _applySelectedMember(FamilyMember p) {
    selectedPatientId.value = p.patientId?.trim() ?? '';
    selectedPatientName.value = (p.fullName?.trim().isNotEmpty == true)
        ? p.fullName!.trim()
        : (p.isSelf ? 'You' : 'Patient');
    selectedPatientRelation.value =
        p.isSelf ? 'Me' : (p.relation?.name ?? 'Member');
    selectedPatientPhoto.value = p.profilePhoto?.trim() ?? '';
    selectedIsSelf.value = p.isSelf;
  }

  Future<void> syncSelectedPatientFromHome() async {
    final saved =
        (await StorageService().getString(StorageService.selectedPatientId))
            .trim();

    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (home.patients.isEmpty) {
        await home.fetchFamilyMembers();
      }
      // Prefer stored patient_id (source of truth after tap/select).
      if (saved.isNotEmpty) {
        final match = home.patients.firstWhereOrNull(
          (p) => (p.patientId?.trim() ?? '') == saved,
        );
        if (match != null) {
          _applySelectedMember(match);
          return;
        }
        selectedPatientId.value = saved;
        return;
      }
      final p = home.selectedPatient;
      if (p != null) {
        _applySelectedMember(p);
        return;
      }
    }

    if (saved.isNotEmpty) {
      selectedPatientId.value = saved;
    }
  }

  Future<void> selectMember(FamilyMember member, {int? index}) async {
    if (member.recordsLocked) {
      AppToast.showToast(
        msg: member.needsLoginAccess
            ? '${member.fullName ?? 'This member'} is 18 or older. Give them login access so they can grant you permission.'
            : (member.parentPermission?.isDeclined == true
                ? '${member.fullName ?? 'This member'} declined record access.'
                : 'Waiting for ${member.fullName ?? 'this member'} to grant record permission.'),
      );
      return;
    }
    _applySelectedMember(member);
    final id = member.patientId?.trim() ?? '';
    await StorageService().setString(StorageService.selectedPatientId, id);
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (index != null) {
        home.changePatient(index);
      } else {
        home.selectPatientById(id);
      }
    }
    await refreshForSelectedPatient();
  }

  Future<void> refreshForSelectedPatient() async {
    diseases.clear();
    medications.clear();
    timelineEvents.clear();
    await Future.wait([
      fetchDiseases(),
      fetchCurrentMedications(),
      fetchGlobalTimeline(),
    ]);
  }

  @override
  void onInit() {
    super.onInit();
    fetchDiseaseMeta();
    _bootstrapRecords();
  }

  Future<void> _bootstrapRecords() async {
    await syncSelectedPatientFromHome();
    await refreshForSelectedPatient();
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
        patientQuery(),
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
        "${WebApiConstant.API_URL_RECORDS_DISEASES_Details}",
        patientQuery({"disease_uuid": uuid}),
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        print("details Response....$data");
        if (data != null) {
          selectedDisease.value = DiseaseResult.fromJson(data);
          final embedded = selectedDisease.value?.appointments;
          if (embedded != null && embedded.isNotEmpty) {
            diseaseAppointments.value = embedded;
          }
          fetchDiseaseAppointments(uuid);
          // Fetch related data (medications load on Medications tab)
          fetchDiseaseTimeline(uuid);
          fetchDiseaseDocuments(uuid);
          fetchReportTypesMeta();
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease detail: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Current Medications (Health Record → Medications tab) ───────────────
  // GET /medications/?active=1  |  POST /medications/
  // Do NOT use disease/{uuid} APIs here.

  Future<void> fetchCurrentMedications() async {
    try {
      isCurrentMedicationsLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_MEDICATIONS,
        patientQuery({"active": 1}),
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        medications.value = _parseMedicationList(response.data);
      }
    } catch (e) {
      debugPrint("Error fetching current medications: $e");
    } finally {
      isCurrentMedicationsLoading.value = false;
    }
  }

  String _medicationApiMessage(dynamic raw, {String fallback = 'Failed to save medication'}) {
    if (raw is Map) {
      final msg = raw['message']?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
      final data = raw['data'];
      if (data is Map && data.isNotEmpty) {
        final first = data.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return first.toString();
      }
    }
    return fallback;
  }

  void _toastMedicationError(dynamic raw, {String fallback = 'Failed to save medication'}) {
    AppToast.showToast(msg: _medicationApiMessage(raw, fallback: fallback));
  }

  Future<bool> addCurrentMedication(Map<String, dynamic> body) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      attachPatientId(body);
      // POST /health-records/medications/
      var response = await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_CURRENT_MEDICATIONS_ADD,
        body,
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data;
        if (raw is Map && raw['error'] == true) {
          _toastMedicationError(raw);
          return false;
        }
        await fetchCurrentMedications();
        return true;
      }
      _toastMedicationError(response?.data);
      return false;
    } catch (e) {
      debugPrint("Error adding current medication: $e");
      AppToast.showToast(msg: 'Failed to save medication');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// GET /health-records/medications/?medication_uuid=...
  Future<Medication?> fetchMedicationDetail(String medicationUuid) async {
    try {
      isMedicationDetailLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_MEDICATIONS}",
        patientQuery({"medication_uuid": medicationUuid}),
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        final raw = response.data;
        Map<String, dynamic>? json;
        if (raw is Map) {
          if (raw['data'] is Map) {
            json = Map<String, dynamic>.from(raw['data']);
          } else {
            json = Map<String, dynamic>.from(raw);
          }
        }
        if (json != null) {
          final med = Medication.fromJson(json);
          selectedMedication.value = med;
          return med;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching medication detail: $e");
      return null;
    } finally {
      isMedicationDetailLoading.value = false;
    }
  }

  /// POST /health-records/medications/taken/?medication_uuid=...
  /// Body: { reminder_uuid, time }
  Future<bool> markMedicationTaken({
    required String medicationUuid,
    required String reminderUuid,
    required String time,
  }) async {
    try {
      if (medicationUuid.trim().isEmpty ||
          reminderUuid.trim().isEmpty ||
          time.trim().isEmpty) {
        AppToast.showToast(msg: "Missing dose details");
        return false;
      }

      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final body = <String, dynamic>{
        "reminder_uuid": reminderUuid.trim(),
        "time": time.trim(),
      };
      attachPatientId(body);

      final url =
          "${WebApiConstant.API_URL_RECORDS_MEDICATION_TAKEN}?medication_uuid=${Uri.encodeQueryComponent(medicationUuid.trim())}";

      final response = await ApiProvider().requestPostForApi(
        Get.context,
        url,
        body,
        token ?? "",
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data;
        final ok = raw is! Map || raw['error'] != true;
        if (ok) {
          await fetchMedicationDetail(medicationUuid);
          await fetchCurrentMedications();
          AppToast.showToast(msg: "Marked as taken");
          return true;
        }
        AppToast.showToast(
            msg: (raw is Map ? raw['message']?.toString() : null) ??
                "Could not mark as taken");
      }
      return false;
    } catch (e) {
      debugPrint("Error marking medication taken: $e");
      AppToast.showToast(msg: "Something went wrong");
      return false;
    }
  }

  List<Medication> _parseMedicationList(dynamic responseData) {
    List results = [];
    if (responseData is Map) {
      final data = responseData['data'];
      if (data is Map && data['results'] != null) {
        results = data['results'] as List;
      } else if (data is List) {
        results = data;
      } else if (responseData['results'] != null) {
        results = responseData['results'] as List;
      }
    }
    return results.map((e) => Medication.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  // ─── Disease Medications (Disease Details screen) ──────────────────────────
  // GET /diseases/{disease_uuid}/medications/
  // GET /diseases/medications/?disease_uuid=...
  // POST /diseases/medications/  (body includes disease_uuid)

  /// Disease-scoped medications. disease_uuid as query param (not in path).
  Future<void> fetchDiseaseMedications(String diseaseUuid) async {
    try {
      isMedicationsLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}medications/",
        patientQuery({"disease_uuid": diseaseUuid.trim()}),
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        diseaseMedications.value = _parseMedicationList(response.data);
      }
    } catch (e) {
      debugPrint("Error fetching disease medications: $e");
    } finally {
      isMedicationsLoading.value = false;
    }
  }

  Future<bool> addDiseaseMedication({
    required Map<String, dynamic> body,
    String? appointmentUuid,
  })
  async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      attachPatientId(body);
      attachAppointmentUuid(body, appointmentUuid);
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      attachPatientId(body);
      var response = await ApiProvider().requestPostForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}medications/",
        body,
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data;
        if (raw is Map && raw['error'] == true) {
          _toastMedicationError(raw);
          return false;
        }
        await fetchDiseaseMedications(body['disease_uuid']?.toString() ?? '');
        return true;
      }
      _toastMedicationError(response?.data);
      return false;
    } catch (e) {
      debugPrint("Error adding disease medication: $e");
      AppToast.showToast(msg: 'Failed to save medication');
      return false;
    } finally {
      isLoading.value = false;
    }
  }catch(e){
    debugPrint("Error adding disease medication: $e");}
    return false;
  }

  /// Kept for callers — disease-scoped add.
  Future<bool> addMedication({
    required String diseaseUuid,
    required Map<String, dynamic> body,
    String? appointmentUuid,
  }) =>
      addDiseaseMedication(body: body, appointmentUuid: appointmentUuid);

  /// Edit uses medication UUID only. Refresh the list that was edited.
  Future<bool> updateMedication({
    required String medicationUuid,
    required Map<String, dynamic> body,
    String? diseaseUuid,
    bool isCurrentMedication = false,
  }) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      attachPatientId(body);
      var response = await ApiProvider().requestPatchForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_MEDICATIONS}$medicationUuid/",
        body,
        token ?? "",
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data;
        if (raw is Map && raw['error'] == true) {
          _toastMedicationError(raw);
          return false;
        }
        if (isCurrentMedication || diseaseUuid == null || diseaseUuid.isEmpty) {
          await fetchCurrentMedications();
        } else {
          await fetchDiseaseMedications(diseaseUuid);
        }
        // Keep open detail screen in sync without manual refresh.
        if (selectedMedication.value?.id == medicationUuid ||
            selectedMedication.value == null) {
          await fetchMedicationDetail(medicationUuid);
        }
        return true;
      }
      _toastMedicationError(response?.data);
      return false;
    } catch (e) {
      debugPrint("Error updating medication: $e");
      AppToast.showToast(msg: 'Failed to save medication');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete uses medication UUID only.
  Future<bool> deleteMedication({
    required String medicationUuid,
    String? diseaseUuid,
    bool isCurrentMedication = false,
  }) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      var response = await ApiProvider().requestDeleteForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_MEDICATIONS}$medicationUuid/",
        token ?? "",
      );

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 201)) {
        if (isCurrentMedication || diseaseUuid == null || diseaseUuid.isEmpty) {
          await fetchCurrentMedications();
        } else {
          await fetchDiseaseMedications(diseaseUuid);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting medication: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> searchMedicines(String keyword) async {
    try {
      if (keyword.trim().isEmpty) {
        medicineSearchResults.clear();
        return [];
      }
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_MEDICINES_SEARCH,
        {"q": keyword.trim()},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        List results = [];
        if (data is Map && data['results'] != null) {
          results = data['results'] as List;
        } else if (data is List) {
          results = data;
        } else if (response.data['results'] != null) {
          results = response.data['results'] as List;
        }
        medicineSearchResults.value =
            results.map((e) => Map<String, dynamic>.from(e)).toList();
        return medicineSearchResults.toList();
      }
      medicineSearchResults.clear();
      return [];
    } catch (e) {
      debugPrint("Error searching medicines: $e");
      medicineSearchResults.clear();
      return [];
    }
  }

  Future<void> fetchDiseaseTimeline(String uuid) async {
    try {
      isTimelineLoading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_DISEASE_TIMELINE,
        patientQuery({"disease_uuid": uuid.trim()}),
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data is Map ? response.data['data'] : null;
        if (data is Map && data['results'] is List) {
          diseaseTimeline.value = (data['results'] as List)
              .whereType<Map>()
              .map((e) => TimelineEvent.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          diseaseTimeline.clear();
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease timeline: $e");
    } finally {
      isTimelineLoading.value = false;
    }
  }

  Future<void> fetchDiseaseDocuments(String uuid, {String? docType}) async {
    try {
      isDocumentsLoading.value = true;
      final cleanUuid = uuid.trim();
      final type = (docType ?? documentTypeFilter.value).trim();
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      final query = patientQuery({
        'disease_uuid': cleanUuid,
        if (type.isNotEmpty) 'doc_type': type,
      });

      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_DISEASE_DOCUMENTS,
        query,
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        var data = response.data['data'];
        if (data != null && data['results'] != null) {
          diseaseDocuments.value = (data['results'] as List)
              .map((e) =>
                  DiseaseDocument.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          diseaseDocuments.clear();
        }
      }
    } catch (e) {
      debugPrint("Error fetching disease documents: $e");
    } finally {
      isDocumentsLoading.value = false;
    }
  }

  Future<void> setDocumentTypeFilter(String diseaseUuid, String type) async {
    documentTypeFilter.value = type;
    await fetchDiseaseDocuments(diseaseUuid, docType: type);
  }

  Future<void> fetchReportTypesMeta() async {
    try {
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_MASTER_REPORT_TYPES,
        {},
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map) {
          final docs = data['document_types'];
          if (docs is List) {
            documentTypes.value = docs
                .map((e) => DocumentTypeOption.fromJson(
                    Map<String, dynamic>.from(e)))
                .where((e) => e.value.isNotEmpty)
                .toList();
          }
          final reports = data['report_types'];
          if (reports is List) {
            reportTypes.value = reports
                .map((e) =>
                    ReportTypeInfo.fromJson(Map<String, dynamic>.from(e)))
                .where((e) => (e.code ?? '').isNotEmpty)
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching report types: $e");
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

  /// Upload prescription/report with up to 3 files.
  Future<bool> uploadDiseaseDocumentFull({
    required String diseaseUuid,
    required String title,
    required String docType,
    required List<String> filePaths,
    String summary = '',
    String notes = '',
    String? reportTypeCode,
    String? documentDate,
    String? appointmentUuid,
  }) async {
    try {
      if (filePaths.isEmpty) return false;
      isDocumentUploading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      final formMap = <String, dynamic>{
        'disease_uuid': diseaseUuid.trim(),
        'title': title.trim(),
        'summary': summary.trim(),
        'doc_type': docType.trim(),
        'notes': notes.trim(),
        if (documentDate != null && documentDate.trim().isNotEmpty)
          'document_date': documentDate.trim(),
        if (docType == 'report' &&
            reportTypeCode != null &&
            reportTypeCode.trim().isNotEmpty)
          'report_type_code': reportTypeCode.trim(),
      };
      attachPatientId(formMap);
      attachAppointmentUuid(formMap, appointmentUuid);

      final formData = dio.FormData.fromMap(formMap);
      final limited = filePaths.take(3).toList();
      for (final path in limited) {
        formData.files.add(MapEntry(
          'file',
          await dio.MultipartFile.fromFile(path),
        ));
      }

      var response = await ApiProvider().requestMultipartApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_DISEASE_DOCUMENTS,
        formData,
        token ?? "",
      );

      final ok = response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          (response.data is! Map || response.data['error'] != true);

      if (ok) {
        documentTypeFilter.value = docType;
        await fetchDiseaseDocuments(diseaseUuid, docType: docType);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error uploading document: $e");
      return false;
    } finally {
      isDocumentUploading.value = false;
    }
  }

  /// Legacy helper used by older callers.
  Future<bool> uploadDiseaseDocument(
      String uuid, String filePath, String type) async {
    final docType = type == 'bill' ? 'report' : 'prescription';
    return uploadDiseaseDocumentFull(
      diseaseUuid: uuid,
      title: docType == 'prescription' ? 'Prescription' : 'Report',
      docType: docType,
      filePaths: [filePath],
    );
  }

  Future<Map<String, dynamic>?> scanPrescription(String filePath, {String? diseaseUuid, String? appointmentUuid}) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      var formData = dio.FormData.fromMap({
        'image': await dio.MultipartFile.fromFile(filePath),
      });

      if (diseaseUuid != null && diseaseUuid.isNotEmpty) {
        formData.fields.add(MapEntry('disease', diseaseUuid));
        formData.fields.add(MapEntry('disease_uuid', diseaseUuid));
      } else {
        formData.fields.add(const MapEntry('new_disease_name', 'General Health'));
      }
      final apt = appointmentUuid?.trim() ?? '';
      if (apt.isNotEmpty) {
        formData.fields.add(MapEntry('appointment_uuid', apt));
      }
      final pid = selectedPatientId.value.trim();
      if (pid.isNotEmpty) {
        formData.fields.add(MapEntry('patient_id', pid));
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

  Future<bool> reviewPrescription(String uuid, Map<String, dynamic> data, {String? diseaseUuid, String? appointmentUuid}) async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      if (diseaseUuid != null && diseaseUuid.isNotEmpty) {
        data['disease'] = diseaseUuid;
      } else if (!data.containsKey('disease') && !data.containsKey('new_disease_name')) {
        data['new_disease_name'] = 'General Health';
      }
      // Backend review endpoint is PATCH /prescriptions/review/ (uuid in body).
      data['uuid'] = uuid;
      data['prescription_uuid'] = uuid;
      attachPatientId(data);
      attachAppointmentUuid(data, appointmentUuid);

      var response = await ApiProvider().requestPatchForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_PRESCRIPTIONS}review/",
        data,
        token ?? "",
      );

      final reviewOk = response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          (response.data is! Map || response.data['error'] != true);

      if (!reviewOk) {
        return false;
      }

      // Finalize after review edits.
      final confirmBody = <String, dynamic>{
        'uuid': uuid,
        'prescription_uuid': uuid,
      };
      if (diseaseUuid != null && diseaseUuid.isNotEmpty) {
        confirmBody['disease'] = diseaseUuid;
      }
      attachPatientId(confirmBody);
      attachAppointmentUuid(confirmBody, appointmentUuid);

      final confirm = await ApiProvider().requestPostForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_PRESCRIPTIONS}confirm/",
        confirmBody,
        token ?? "",
      );

      final confirmOk = confirm != null &&
          (confirm.statusCode == 200 || confirm.statusCode == 201) &&
          (confirm.data is! Map || confirm.data['error'] != true);

      if (confirmOk || reviewOk) {
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
    // Remove from UI immediately so Dismissible can leave the tree.
    final removedIndex = diseases.indexWhere((e) => e.uuid == uuid);
    final removed = removedIndex >= 0 ? diseases[removedIndex] : null;
    if (removedIndex >= 0) {
      diseases.removeAt(removedIndex);
    }

    try {
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      var response = await ApiProvider().requestDeleteForApi(
        Get.context,
        "${WebApiConstant.API_URL_RECORDS_DISEASES}$uuid/",
        token ?? "",
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        AppToast.showToast(msg: "Disease deleted successfully");
      } else if (removed != null) {
        // API failed — restore item in list.
        final insertAt = removedIndex.clamp(0, diseases.length);
        diseases.insert(insertAt, removed);
        AppToast.showToast(msg: "Failed to delete disease");
      }
    } catch (e) {
      debugPrint("Error deleting disease: $e");
      if (removed != null) {
        final insertAt = removedIndex.clamp(0, diseases.length);
        diseases.insert(insertAt, removed);
        AppToast.showToast(msg: "Failed to delete disease");
      }
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
        AppToast.showToast(msg: "Disease archived successfully");
      }
    } catch (e) {
      debugPrint("Error archiving disease: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> exportDiseasePdf(String uuid) async {
    try {
      isLoading.value = true;
      final cleanUuid = uuid.trim();

      // Always ensure disease + meds are ready before opening preview
      // (first visit often has empty lists because tabs weren't opened yet).
      if (selectedDisease.value == null ||
          selectedDisease.value?.uuid != cleanUuid) {
        await fetchDiseaseDetail(cleanUuid);
      }
      await Future.wait([
        fetchDiseaseMedications(cleanUuid),
        fetchDiseaseTimeline(cleanUuid),
      ]);

      if (selectedDisease.value == null) {
        AppToast.showToast(msg: "No disease data available to export");
        return;
      }

      if (!Get.isRegistered<ProfileController>()) {
        Get.put(ProfileController());
      }
      final profile = Get.find<ProfileController>();
      final ctx = Get.context;
      // Wait for patient profile so PDF patient section isn't blank on first open.
      if (ctx != null && profile.fullNameCtrl.text.trim().isEmpty) {
        await profile.getPatientProfileAPI(ctx);
      }

      await Get.to(() => DiseasePdfPreviewScreen(
            disease: selectedDisease.value!,
            medications: List<Medication>.from(diseaseMedications),
            timeline: List<TimelineEvent>.from(diseaseTimeline),
          ));
    } catch (e) {
      debugPrint("Error generating PDF: $e");
      AppToast.showToast(msg: "Error generating PDF");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchGlobalTimeline({String eventType = "", String disease = "", String dateFrom = "", String dateTo = ""}) async {
    try {
      isTimelineLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      Map<String, dynamic> query = patientQuery({
        "event_type": eventType,
        "disease": disease,
        "date_from": dateFrom,
        "date_to": dateTo,
      });

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
      attachPatientId(body);

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
      attachPatientId(body);

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

  // ─── Disease appointments ─────────────────────────────────────────────────

  Future<void> fetchDiseaseAppointments(String diseaseUuid) async {
    try {
      isAppointmentsLoading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_APPOINTMENTS,
        patientQuery({
          'disease_uuid': diseaseUuid.trim(),
          'page': 1,
          'page_size': 50,
        }),
        token ?? "",
      );

      if (response != null && response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map && raw['error'] == true) {
          AppToast.showToast(
              msg: _apiMessage(raw, fallback: 'Failed to load appointments'));
          return;
        }
        dynamic payload = raw is Map ? raw['data'] : null;
        List results = const [];
        if (payload is Map && payload['results'] is List) {
          results = payload['results'] as List;
        } else if (payload is List) {
          results = payload;
        }
        diseaseAppointments.value = DiseaseAppointment.listFrom(results);
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    } finally {
      isAppointmentsLoading.value = false;
    }
  }

  Future<bool> scheduleAppointment({
    required String diseaseUuid,
    required String date,
    required String time,
    String notes = '',
  }) async {
    try {
      isLoading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final body = <String, dynamic>{
        'disease_uuid': diseaseUuid.trim(),
        'date': date.trim(),
        'time': time.trim(),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
      attachPatientId(body);

      var response = await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_APPOINTMENTS,
        body,
        token ?? "",
      );

      final raw = response?.data;
      if (raw is Map && raw['error'] == true) {
        AppToast.showToast(
            msg: _apiMessage(raw, fallback: 'Failed to schedule appointment'));
        return false;
      }
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        AppToast.showToast(
            msg: (raw is Map ? raw['message']?.toString() : null) ??
                'Appointment scheduled successfully.');
        await fetchDiseaseAppointments(diseaseUuid);
        await fetchDiseaseDetail(diseaseUuid);
        await fetchDiseases();
        return true;
      }
      AppToast.showToast(msg: 'Failed to schedule appointment');
      return false;
    } catch (e) {
      debugPrint("Error scheduling appointment: $e");
      AppToast.showToast(msg: 'Failed to schedule appointment');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<AppointmentDetail?> fetchAppointmentDetail(
      String appointmentUuid) async {
    try {
      isAppointmentDetailLoading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      var response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_APPOINTMENT_DETAIL,
        patientQuery({'appointment_uuid': appointmentUuid.trim()}),
        token ?? "",
      );

      final raw = response?.data;
      if (response != null && response.statusCode == 404) {
        AppToast.showToast(
            msg: _apiMessage(raw, fallback: 'Appointment not found.'));
        return null;
      }
      if (raw is Map && raw['error'] == true) {
        AppToast.showToast(
            msg: _apiMessage(raw, fallback: 'Appointment not found.'));
        return null;
      }
      if (response != null && response.statusCode == 200 && raw is Map) {
        final data = raw['data'];
        if (data is Map) {
          final detail =
              AppointmentDetail.fromJson(Map<String, dynamic>.from(data));
          selectedAppointment.value = detail;
          return detail;
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching appointment detail: $e");
      return null;
    } finally {
      isAppointmentDetailLoading.value = false;
    }
  }

  Future<bool> cancelAppointment({
    required String appointmentUuid,
    required String diseaseUuid,
  }) async {
    try {
      isLoading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final body = <String, dynamic>{
        'appointment_uuid': appointmentUuid.trim(),
      };
      attachPatientId(body);

      var response = await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_RECORDS_APPOINTMENT_CANCEL,
        body,
        token ?? "",
      );

      final raw = response?.data;
      if (raw is Map && raw['error'] == true) {
        AppToast.showToast(
            msg: _apiMessage(raw, fallback: 'Failed to cancel appointment'));
        return false;
      }
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        AppToast.showToast(
            msg: (raw is Map ? raw['message']?.toString() : null) ??
                'Appointment cancelled successfully.');
        await fetchDiseaseAppointments(diseaseUuid);
        await fetchDiseaseDetail(diseaseUuid);
        await fetchDiseases();
        if (selectedAppointment.value?.uuid == appointmentUuid) {
          await fetchAppointmentDetail(appointmentUuid);
        }
        return true;
      }
      AppToast.showToast(msg: 'Failed to cancel appointment');
      return false;
    } catch (e) {
      debugPrint("Error cancelling appointment: $e");
      AppToast.showToast(msg: 'Failed to cancel appointment');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> uploadConsultationRecording({
    required String appointmentUuid,
    required String filePath,
  }) async {
    try {
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final form = dio.FormData.fromMap({
        'appointment_uuid': appointmentUuid.trim(),
        'audio': await dio.MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });
      final pid = selectedPatientId.value.trim();
      if (pid.isNotEmpty) {
        form.fields.add(MapEntry('patient_id', pid));
      }
      final response = await ApiProvider().requestMultipartApi(
        Get.context,
        WebApiConstant.API_URL_CONSULTATION_RECORDINGS,
        form,
        token ?? '',
      );
      final raw = response?.data;
      if (raw is Map && raw['error'] == true) {
        AppToast.showToast(
            msg: _apiMessage(raw, fallback: 'Could not upload recording.'));
        return null;
      }
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          raw is Map) {
        final data = raw['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      AppToast.showToast(msg: 'Could not upload recording.');
      return null;
    } catch (e) {
      debugPrint('Error uploading consultation recording: $e');
      AppToast.showToast(msg: 'Could not upload recording.');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchConsultationTranscript(
      String recordingUuid) async {
    try {
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_CONSULTATION_TRANSCRIPT,
        {'recording_uuid': recordingUuid.trim()},
        token ?? '',
        timeout: const Duration(seconds: 8),
      );
      final raw = response?.data;
      if (raw is Map && raw['error'] != true && raw['data'] is Map) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching transcript: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> pollConsultationTranscript(
      String recordingUuid) async {
    Map<String, dynamic>? last;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    for (var i = 0; i < 20; i++) {
      if (i > 0) await Future.delayed(const Duration(seconds: 1));
      last = await fetchConsultationTranscript(recordingUuid);
      if (last == null) continue;
      final status = (last['status'] ?? '').toString().toLowerCase();
      final text = (last['formatted_transcript'] ??
              last['transcript'] ??
              last['raw_transcript'] ??
              '')
          .toString()
          .trim();
      if (status == 'completed' ||
          status == 'failed' ||
          status == 'error' ||
          text.isNotEmpty) {
        return last;
      }
    }
    return last;
  }

  Future<List<Map<String, dynamic>>> fetchConsultationRecordings(
      String appointmentUuid) async {
    try {
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final q = patientQuery({'appointment_uuid': appointmentUuid.trim()});
      final response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_CONSULTATION_RECORDINGS,
        q,
        token ?? '',
      );
      final raw = response?.data;
      if (raw is! Map || raw['error'] == true) return [];
      final data = raw['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is Map) {
        final results = data['results'];
        if (results is List) {
          return results
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error listing consultation recordings: $e');
      return [];
    }
  }
}
