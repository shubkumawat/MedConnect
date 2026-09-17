import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../DataProvider/api_provider.dart';
import 'package:healaura/DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import 'package:healaura/app/core/Util/Print/print_log.dart';
import 'package:healaura/app/core/Util/home_address.dart';
import 'package:healaura/app/core/Util/image_pick_helper.dart';
import 'package:healaura/app/core/Util/TextValidator/text_validation.dart';
import 'package:healaura/app/data/services/storage_service.dart';
import 'package:healaura/app/data/models/family_member_model.dart';
import 'package:healaura/app/data/models/menstrual_cycle_model.dart';

import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../data/models/risk_factor_model.dart';
import '../../home/controllers/home_controller.dart';
import 'package:healaura/app/core/Util/app_toast.dart';


/// Master relation list ka model
class RelationModel {
  final int id;
  final String name;
  final String code;

  RelationModel({required this.id, required this.name, required this.code});

  factory RelationModel.fromJson(Map<String, dynamic> json) {
    return RelationModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class OccupationModel {
  final int id;
  final String name;
  final String code;

  OccupationModel({required this.id, required this.name, required this.code});

  factory OccupationModel.fromJson(Map<String, dynamic> json) {
    return OccupationModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class DisabilityTypeModel {
  final int id;
  final String disabilityTypeId;
  final String name;
  final String code;

  DisabilityTypeModel({
    required this.id,
    required this.disabilityTypeId,
    required this.name,
    required this.code,
  });

  factory DisabilityTypeModel.fromJson(Map<String, dynamic> json) {
    return DisabilityTypeModel(
      id: json['id'] ?? 0,
      disabilityTypeId: json['disability_type_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class FamilyMemberController extends GetxController {
  String? userAccessToken;
  RxBool isLoading = false.obs;

  // Mode: Add or Update
  RxBool isUpdateMode = false.obs;
  String? currentPatientId;

  // ---------------- Image Picker ----------------
  Rx<File?> profileImage = Rx<File?>(null);

  Future<void> pickImage(ImageSource source) async {
    try {
      final file = await ImagePickHelper.pick(
        source: source,
        imageQuality: 70,
      );
      if (file != null) {
        profileImage.value = file;
      }
    } catch (e) {
      PrintLog.printLog("Pick Image Error: $e");
      AppToast.showToast(msg: 'Could not pick image');
    }
  }

  // ---------------- List & Count ----------------
  RxList<FamilyMember> familyMemberList = <FamilyMember>[].obs;
  RxInt familyMemberCount = 0.obs;
  Rxn<FamilyMember> familyMemberDetail = Rxn<FamilyMember>();

  // ---------------- Access Management ----------------
  RxBool fullAccess = false.obs;
  RxBool emergencyOnly = false.obs;

  Future<void> updateAccessControl(BuildContext context, bool isFullAccess, bool value) async {
    if (familyMemberDetail.value == null) return;
    
    try {
      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      // Mutual exclusivity: full vs emergency-only.
      final bool newFullAccess;
      final bool newEmergencyOnly;
      if (isFullAccess) {
        newFullAccess = value;
        newEmergencyOnly = value ? false : emergencyOnly.value;
      } else {
        newEmergencyOnly = value;
        newFullAccess = value ? false : fullAccess.value;
      }

      final response = await ApiProvider().updateAccessControlAPI(
        context,
        WebApiConstant.API_URL_UPDATE_ACCESS_CONTROL,
        {
          "patient_id": familyMemberDetail.value!.patientId!,
          "full_access": newFullAccess,
          "emergency_only": newEmergencyOnly,
        },
        userAccessToken ?? '',
      );

      isLoading.value = false;
      if (response != null && response['error'] != true) {
        fullAccess.value = newFullAccess;
        emergencyOnly.value = newEmergencyOnly;
        final detail = familyMemberDetail.value;
        if (detail != null) {
          detail.fullAccess = newFullAccess;
          detail.emergencyOnly = newEmergencyOnly;
          detail.accessGiven = newFullAccess || newEmergencyOnly;
          familyMemberDetail.refresh();
        }
        // Keep list chips in sync.
        final id = detail?.patientId;
        if (id != null) {
          final i = familyMemberList.indexWhere((e) => e.patientId == id);
          if (i >= 0) {
            familyMemberList[i].fullAccess = newFullAccess;
            familyMemberList[i].emergencyOnly = newEmergencyOnly;
            familyMemberList[i].accessGiven = newFullAccess || newEmergencyOnly;
            familyMemberList.refresh();
          }
        }
        AppToast.showToast(msg: response['message'] ?? "Access updated");
      } else {
        AppToast.showToast(msg: response?['message'] ?? "Failed to update access");
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Access Control Exception: $e");
    }
  }

  // ---------------- Personal ----------------
  final fullNameCtrl = TextEditingController();
  final mobileNumberCtrl = TextEditingController();
  /// Optional Ayushman Bharat Health Account (ABHA) / Health ID.
  final abhaNumberCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  Rx<DateTime?> selectedDob = Rx<DateTime?>(null);

  RxString selectedGender = ''.obs;
  final genders = ['Male', 'Female', 'Other'];

  // ---------------- Relation (master relation API) ----------------
  RxBool isRelationLoading = false.obs;
  RxList<RelationModel> relationList = <RelationModel>[].obs;
  Rx<RelationModel?> selectedRelationModel = Rx<RelationModel?>(null);

  RxString selectedRelation = ''.obs;
  // Removed hardcoded relations list as we use relationList from API

  // ---------------- Nationality (master country API) ----------------
  RxBool isCountryLoading = false.obs;
  RxList<CountryModel> countryList = <CountryModel>[].obs;
  Rx<CountryModel?> selectedCountry = Rx<CountryModel?>(null);

  // ---------------- Occupation (master occupation API) ----------------
  RxBool isOccupationLoading = false.obs;
  RxList<OccupationModel> occupationList = <OccupationModel>[].obs;
  Rx<OccupationModel?> selectedOccupationModel = Rx<OccupationModel?>(null);

  // ---------------- Disability Type ----------------
  RxBool isDisabilityLoading = false.obs;
  RxList<DisabilityTypeModel> disabilityTypeList = <DisabilityTypeModel>[].obs;
  Rx<DisabilityTypeModel?> selectedDisabilityTypeModel = Rx<DisabilityTypeModel?>(null);

  // ---------------- Medical ----------------
  RxString bloodGroup = ''.obs;
  final bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
    'Unknown',
  ];
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  RxString maritalStatus = ''.obs;
  final maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];
  final occupationCtrl = TextEditingController();

  RxBool hasChronicDisease = false.obs;
  RxBool isPhysicallyHandicapped = false.obs;
  final disabilityTypeCtrl = TextEditingController();
  RxBool isOrganDonor = false.obs;

  final allergyTags = ['Penicillin', 'Peanuts', 'Latex', 'Dust', 'Milk', 'Dairy'];
  RxList<String> selectedAllergies = <String>[].obs;
  RxList<RiskFactor> riskFactorList = <RiskFactor>[].obs;
  RxList<String> selectedRiskFactors = <String>[].obs;
  RxBool isRiskFactorLoading = false.obs;

  final medicationInputCtrl = TextEditingController();
  RxList<String> selectedMedications = <String>[].obs;

  void toggleAllergy(String tag) {
    if (selectedAllergies.contains(tag)) {
      selectedAllergies.remove(tag);
    } else {
      selectedAllergies.add(tag);
    }
  }

  void toggleRiskFactor(String value) {
    if (selectedRiskFactors.contains(value)) {
      selectedRiskFactors.remove(value);
    } else {
      selectedRiskFactors.add(value);
    }
  }

  void addMedication() {
    final val = medicationInputCtrl.text.trim();
    if (val.isNotEmpty && !selectedMedications.contains(val)) {
      selectedMedications.add(val);
      medicationInputCtrl.clear();
    }
  }

  void removeMedication(String tag) {
    selectedMedications.remove(tag);
  }

  // ---------------- Emergency & Insurance ----------------
  final addressLineCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final postCodeCtrl = TextEditingController();
  RxString selectedState = ''.obs;
  final states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
    'Uttarakhand', 'West Bengal', 'Andaman and Nicobar Islands',
    'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 'Delhi',
    'Jammu and Kashmir', 'Ladakh', 'Ladakh', 'Puducherry'
  ];

  final contactNameCtrl = TextEditingController();
  Rx<RelationModel?> selectedContactRelationModel = Rx<RelationModel?>(null);
  RxString contactRelation = ''.obs;
  final contactRelations = ['Spouse', 'Parent', 'Sibling', 'Friend', 'Other'];
  final contactMobileCtrl = TextEditingController();

  final insuranceProviderCtrl = TextEditingController();
  final policyNumberCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    selectedCountry.value = CountryModel.indiaFallback;
    _loadToken();
  }

  Future<void> _loadToken() async {
    userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
  }

  Future<void> getRiskFactorsAPI(BuildContext context) async {
    try {
      isRiskFactorLoading.value = true;
      userAccessToken =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().requestGetForApi(
        context,
        WebApiConstant.API_URL_RISK_FACTORS,
        {},
        userAccessToken ?? '',
      );
      isRiskFactorLoading.value = false;
      final raw = response?.data;
      PrintLog.printLog(raw);
      if (raw is Map && raw['error'] != true && raw['error_code'] == 0) {
        final data = raw['data'];
        final list = data is Map ? data['results'] : data;
        riskFactorList.value = RiskFactor.listFrom(list);
      }
    } catch (e) {
      isRiskFactorLoading.value = false;
      PrintLog.printLog("Exception RiskFactors: $e");
    }
  }

  Future<void> getAllMasterDataAPI(BuildContext context) async {
    try {
      isRelationLoading.value = true;
      isCountryLoading.value = true;
      isOccupationLoading.value = true;
      isDisabilityLoading.value = true;
      
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final response = await ApiProvider().getAllMasterDataAPI(
        context,
        WebApiConstant.API_URL_MASTER_ALL,
        {},
        userAccessToken ?? '',
      );

      isRelationLoading.value = false;
      isCountryLoading.value = false;
      isOccupationLoading.value = false;
      isDisabilityLoading.value = false;

      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final data = response['data'];
          if (data != null) {
            // Relations
            final List relations = data['relations'] ?? [];
            relationList.value = relations.map((e) => RelationModel.fromJson(e)).toList();

            // Countries
            final List countries = data['countries'] ?? [];
            countryList.value = countries.map((e) => CountryModel.fromJson(e)).toList();
            if (familyMemberDetail.value != null) {
              _populateFields(familyMemberDetail.value!);
            } else if (selectedCountry.value == null ||
                selectedCountry.value!.id == 0) {
              selectedCountry.value = CountryModel.indiaFrom(countryList);
            }

            // Occupations
            final List occupations = data['occupations'] ?? [];
            occupationList.value = occupations.map((e) => OccupationModel.fromJson(e)).toList();

            // Disability Types
            final List disabilities = data['disability_types'] ?? [];
            disabilityTypeList.value = disabilities.map((e) => DisabilityTypeModel.fromJson(e)).toList();
          }
        }
      }
      if (Get.context != null) {
        await getRiskFactorsAPI(Get.context!);
      }
    } catch (e) {
      isRelationLoading.value = false;
      isCountryLoading.value = false;
      isOccupationLoading.value = false;
      isDisabilityLoading.value = false;
      PrintLog.printLog("Exception getAllMasterDataAPI: $e");
    }
  }

  Future<void> getMasterRelationAPI(BuildContext context) async {
    try {
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      isRelationLoading.value = true;

      final response = await ApiProvider().getMasterRelationAPI(
        context,
        WebApiConstant.API_URL_MASTER_RELATIONS,
        {},
        userAccessToken ?? '',
      );

      isRelationLoading.value = false;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data']?['relations'] ?? [];
          relationList.value = list.map((e) => RelationModel.fromJson(e)).toList();
        } else {
          AppToast.showToast(msg: response['message']?.toString() ?? '');
        }
      }
    } catch (e) {
      isRelationLoading.value = false;
      PrintLog.printLog("Exception Relation: $e");
    }
  }

  Future<void> getMasterCountryAPI(BuildContext context) async {
    try {
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      isCountryLoading.value = true;

      final response = await ApiProvider().getMasterCountryAPI(
        context,
        WebApiConstant.API_URL_MASTER_COUNTRY,
        {},
        userAccessToken ?? '',
      );

      isCountryLoading.value = false;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data'] ?? [];
          countryList.value = list.map((e) => CountryModel.fromJson(e)).toList();
          if (familyMemberDetail.value == null) {
            if (selectedCountry.value == null ||
                selectedCountry.value!.id == 0) {
              selectedCountry.value = CountryModel.indiaFrom(countryList);
            }
          }
        } else {
          AppToast.showToast(msg: response['message']?.toString() ?? '');
        }
      } else {
        PrintLog.printLog("Unexpected response (not JSON): $response");
        AppToast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isCountryLoading.value = false;
      PrintLog.printLog("Exception: $e");
      AppToast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  Future<void> getMasterOccupationAPI(BuildContext context) async {
    try {
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      isOccupationLoading.value = true;

      final response = await ApiProvider().getMasterOccupationAPI(
        context,
        WebApiConstant.API_URL_MASTER_OCCUPATIONS,
        {},
        userAccessToken ?? '',
      );

      isOccupationLoading.value = false;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data']?['occupations'] ?? [];
          occupationList.value = list.map((e) => OccupationModel.fromJson(e)).toList();
          
          if (occupationCtrl.text.isNotEmpty) {
            selectedOccupationModel.value = occupationList.firstWhereOrNull(
                  (o) => o.code.toLowerCase() == occupationCtrl.text.toLowerCase() ||
                  o.name.toLowerCase() == occupationCtrl.text.toLowerCase(),
            );
          }
        }
      }
    } catch (e) {
      isOccupationLoading.value = false;
      PrintLog.printLog("Exception Occupation: $e");
    }
  }

  Future<void> getMasterDisabilityTypeAPI(BuildContext context) async {
    try {
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      isDisabilityLoading.value = true;

      final response = await ApiProvider().getMasterDisabilityTypeAPI(
        context,
        WebApiConstant.API_URL_MASTER_DISABILITY_TYPES,
        {},
        userAccessToken ?? '',
      );

      isDisabilityLoading.value = false;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data']?['disability_types'] ?? [];
          disabilityTypeList.value = list.map((e) => DisabilityTypeModel.fromJson(e)).toList();

          if (disabilityTypeCtrl.text.isNotEmpty) {
            selectedDisabilityTypeModel.value = disabilityTypeList.firstWhereOrNull(
              (d) => d.code.toLowerCase() == disabilityTypeCtrl.text.toLowerCase() ||
                     d.name.toLowerCase() == disabilityTypeCtrl.text.toLowerCase(),
            );
          }
        }
      }
    } catch (e) {
      isDisabilityLoading.value = false;
      PrintLog.printLog("Exception Disability: $e");
    }
  }

  void clearFields() {
    isUpdateMode.value = false;
    currentPatientId = null;
    familyMemberDetail.value = null;
    profileImage.value = null;

    fullNameCtrl.clear();
    mobileNumberCtrl.clear();
    abhaNumberCtrl.clear();
    dobCtrl.clear();
    selectedDob.value = null;
    selectedGender.value = '';
    selectedRelation.value = '';
    selectedRelationModel.value = null;
    selectedCountry.value = CountryModel.indiaFrom(countryList);

    bloodGroup.value = '';
    heightCtrl.clear();
    weightCtrl.clear();
    maritalStatus.value = '';
    occupationCtrl.clear();
    selectedOccupationModel.value = null;

    hasChronicDisease.value = false;
    isPhysicallyHandicapped.value = false;
    disabilityTypeCtrl.clear();
    selectedDisabilityTypeModel.value = null;
    isOrganDonor.value = false;

    selectedAllergies.clear();
    selectedRiskFactors.clear();
    selectedMedications.clear();
    medicationInputCtrl.clear();

    addressLineCtrl.clear();
    cityCtrl.clear();
    postCodeCtrl.clear();
    selectedState.value = '';

    contactNameCtrl.clear();
    contactRelation.value = '';
    contactMobileCtrl.clear();

    insuranceProviderCtrl.clear();
    policyNumberCtrl.clear();
  }

  // ---------------- API Calls ----------------

  Future<void> getFamilyMemberCountAPI(BuildContext context) async {
    try {
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().getFamilyMemberListAPI(
        context,
        WebApiConstant.API_URL_FAMILY_MEMBER_COUNT,
        {},
        userAccessToken ?? '',
      );

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          familyMemberCount.value = response['data']?['family_member_count'] ?? 0;
        }
      }
    } catch (e) {
      PrintLog.printLog("Count Exception: $e");
    }
  }

  Future<void> getFamilyMemberListAPI(BuildContext context) async {
    try {
      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().getFamilyMemberListAPI(
        context,
        WebApiConstant.API_URL_FAMILY_MEMBER_LIST,
        {},
        userAccessToken ?? '',
      );

      isLoading.value = false;
      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final data = response['data'];
          List list = const [];
          if (data is Map) {
            list = data['family_members'] ??
                data['members'] ??
                data['results'] ??
                [];
          } else if (data is List) {
            list = data;
          }
          familyMemberList.value = list
              .whereType<Map>()
              .map((e) => FamilyMember.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else {
          AppToast.showToast(msg: response['message']?.toString() ?? '');
        }
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("List Exception: $e");
    }
  }

  Future<void> getFamilyMemberDetailAPI(BuildContext context, String patientId) async {
    try {
      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().getFamilyMemberListAPI(
        context,
        "${WebApiConstant.API_URL_FAMILY_MEMBER_DETAIL}?patient_id=$patientId",
        {},
        userAccessToken ?? '',
      );

      isLoading.value = false;
      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          familyMemberDetail.value = FamilyMember.fromJson(response['data']);
          if (familyMemberDetail.value != null) {
            fullAccess.value = familyMemberDetail.value!.fullAccess ?? false;
            emergencyOnly.value = familyMemberDetail.value!.emergencyOnly ?? false;
            _populateFields(familyMemberDetail.value!);
            debugPrint("response...${response.toString()}");
          }
        } else {
          AppToast.showToast(msg: response['message']?.toString() ?? '');
        }
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Detail Exception: $e");
    }
  }

  Future<void> deleteFamilyMember(BuildContext context, String patientId, VoidCallback onSuccess) async {
    try {
      final storage = StorageService();
      String accessType = await storage.getString(StorageService.accessType);
      if (accessType == "2") {
        Get.snackbar(
          "Access Restricted",
          "You don't have permission to delete family members.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().deleteFamilyMemberAPI(
          context,
          "${WebApiConstant.API_URL_DELETE_FAMILY_MEMBER}?patient_id=$patientId",
          userAccessToken ?? ''
      );

      isLoading.value = false;
      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          AppToast.showToast(msg: response['message'] ?? 'Family member deleted successfully.');
          onSuccess();
        } else {
          AppToast.showToast(msg: response['message']?.toString() ?? '');
        }
      } else {
        AppToast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Delete Exception: $e");
      AppToast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  void _populateFields(FamilyMember member) {
    fullNameCtrl.text = member.fullName ?? '';
    final mobileDigits = (member.mobileNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    mobileNumberCtrl.text = mobileDigits.length > TxtValidation.mobileMaxLength
        ? mobileDigits.substring(mobileDigits.length - TxtValidation.mobileMaxLength)
        : mobileDigits;
    abhaNumberCtrl.text = member.abhaNumber ?? '';
    if (member.dateOfBirth != null) {
      selectedDob.value = DateFormat('yyyy-MM-dd').parse(member.dateOfBirth!);
      dobCtrl.text = DateFormat('dd/MM/yyyy').format(selectedDob.value!);
    }
    selectedGender.value = toBeginningOfSentenceCase(member.gender) ?? '';
    
    if (member.relation != null) {
      selectedRelationModel.value = relationList.firstWhereOrNull((r) => r.id == member.relation?.id);
    }

    if (member.nationality != null) {
      selectedCountry.value = countryList.firstWhereOrNull((c) => c.id == member.nationality?.id)
          ?? CountryModel.indiaFrom(countryList);
    } else {
      selectedCountry.value = CountryModel.indiaFrom(countryList);
    }

    bloodGroup.value = member.bloodGroup ?? '';
    heightCtrl.text = member.height ?? '';
    weightCtrl.text = member.weight ?? '';
    maritalStatus.value = toBeginningOfSentenceCase(member.maritalStatus) ?? '';
    if (member.occupation != null) {
      occupationCtrl.text = member.occupation?.name ?? '';
      if (occupationList.isNotEmpty) {
        selectedOccupationModel.value = occupationList.firstWhereOrNull(
          (o) => o.id == member.occupation?.id || 
                 o.code.toLowerCase() == member.occupation?.code?.toLowerCase()
        );
      }
    }

    hasChronicDisease.value = member.medical?.chronicDisease ?? false;
    isPhysicallyHandicapped.value = member.medical?.physicallyHandicapped ?? false;
    disabilityTypeCtrl.text = member.medical?.disabilityType ?? '';
    if (disabilityTypeList.isNotEmpty && disabilityTypeCtrl.text.isNotEmpty) {
      selectedDisabilityTypeModel.value = disabilityTypeList.firstWhereOrNull(
        (d) => d.name.toLowerCase() == disabilityTypeCtrl.text.toLowerCase() ||
               d.code.toLowerCase() == disabilityTypeCtrl.text.toLowerCase()
      );
    }
    isOrganDonor.value = member.medical?.organDonor ?? false;

    selectedAllergies.value = member.medical?.allergies?.map((e) => e.allergyName ?? '').toList() ?? [];
    selectedRiskFactors.value = member.medical?.riskFactors ?? [];
    selectedMedications.value = member.medical?.currentMedications ?? [];

    final home = HomeAddress.parse(member.homeAddress);
    addressLineCtrl.text = home.address;
    cityCtrl.text = home.city;
    postCodeCtrl.text = home.postCode;
    selectedState.value = home.state;

    contactNameCtrl.text = member.emergencyContact?.contactName ?? '';
    final contactDigits =
        (member.emergencyContact?.phoneNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    contactMobileCtrl.text = contactDigits.length > TxtValidation.mobileMaxLength
        ? contactDigits.substring(contactDigits.length - TxtValidation.mobileMaxLength)
        : contactDigits;
    if (member.emergencyContact?.relation != null) {
      selectedContactRelationModel.value = relationList.firstWhereOrNull(
          (r) => r.name.toLowerCase() == member.emergencyContact?.relation?.toLowerCase() || 
                 r.code.toLowerCase() == member.emergencyContact?.relation?.toLowerCase());
      contactRelation.value = selectedContactRelationModel.value?.name ?? toBeginningOfSentenceCase(member.emergencyContact?.relation) ?? '';
    }

    insuranceProviderCtrl.text = member.insurance?.provider ?? '';
    policyNumberCtrl.text = member.insurance?.policyNumber ?? '';
  }

  bool _validate() {
    final nameErr = TxtValidation.personNameError(fullNameCtrl.text);
    if (nameErr != null) {
      AppToast.showToast(msg: nameErr);
      return false;
    }
    final mobileErr = TxtValidation.mobileError(mobileNumberCtrl.text);
    if (mobileErr != null) {
      AppToast.showToast(msg: mobileErr);
      return false;
    }
    if (selectedDob.value == null) {
      AppToast.showToast(msg: 'Please select date of birth');
      return false;
    }
    if (selectedGender.value.isEmpty) {
      AppToast.showToast(msg: 'Please select gender');
      return false;
    }
    if (selectedRelationModel.value == null) {
      AppToast.showToast(msg: 'Please select relation');
      return false;
    }
    final contactName = contactNameCtrl.text.trim();
    final contactNameErr = TxtValidation.personNameError(contactName);
    if (contactNameErr != null) {
      AppToast.showToast(
        msg: contactName.isEmpty
            ? 'Please enter emergency contact name'
            : contactNameErr,
      );
      return false;
    }
    final contactMobileErr =
        TxtValidation.mobileError(contactMobileCtrl.text, required: true);
    if (contactMobileErr != null) {
      AppToast.showToast(msg: contactMobileErr);
      return false;
    }
    return true;
  }

  Future<void> submitFamilyMember(BuildContext context, VoidCallback onSuccess) async {
    if (isUpdateMode.value) {
      updateFamilyMemberAPI(context, onSuccess);
    } else {
      addFamilyMemberAPI(context, onSuccess);
    }
  }

  Future<void> addFamilyMemberAPI(BuildContext context, VoidCallback onSuccess) async {
    if (!_validate()) return;

    try {
      /* final storage = StorageService();
      String accessType = await storage.getString(StorageService.accessType);
      if (accessType == "2") {
        Get.snackbar(
          "Access Restricted",
          "You don't have permission to add family members.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      } */

      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final homeAddress = HomeAddress(
        address: addressLineCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: selectedState.value.trim(),
        postCode: postCodeCtrl.text.trim(),
      ).display;

      final Map<String, dynamic> dictParameter = {
        "full_name": fullNameCtrl.text.trim(),
        "mobile_number": mobileNumberCtrl.text.trim(),
        "abha_number": abhaNumberCtrl.text.trim(),
        "date_of_birth": DateFormat('yyyy-MM-dd').format(selectedDob.value!),
        "gender": selectedGender.value.toLowerCase(),
        "nationality": selectedCountry.value?.id,
        "relation": selectedRelationModel.value?.code,
        "blood_group": bloodGroup.value.toLowerCase() == 'unknown'
            ? 'unknown'
            : bloodGroup.value,
        "height": double.tryParse(heightCtrl.text.trim()) ?? 0,
        "weight": double.tryParse(weightCtrl.text.trim()) ?? 0,
        "marital_status": maritalStatus.value.toLowerCase(),
        "occupation": selectedOccupationModel.value?.code ?? occupationCtrl.text.trim(),
        "chronic_disease": hasChronicDisease.value,
        "physically_handicapped": isPhysicallyHandicapped.value,
        "disability_type": isPhysicallyHandicapped.value ? (selectedDisabilityTypeModel.value?.code ?? disabilityTypeCtrl.text.trim()) : "",
        "organ_donor": isOrganDonor.value,
        "home_address": homeAddress,
        "contact_name": contactNameCtrl.text.trim(),
        "contact_relation": contactRelation.value.toLowerCase(),
        "contact_mobile": contactMobileCtrl.text.trim(),
        "insurance_provider": insuranceProviderCtrl.text.trim(),
        "policy_number": policyNumberCtrl.text.trim(),
        // API expects JSON arrays (same as Postman), not jsonEncode strings.
        "allergies": selectedAllergies.toList(),
        "medications": selectedMedications.toList(),
        "risk_factors": selectedRiskFactors.toList(),
      };

      dynamic response;
      if (profileImage.value != null) {
        final formData = dio.FormData.fromMap(dictParameter);
        formData.files.add(MapEntry(
          "profile_photo",
          await dio.MultipartFile.fromFile(profileImage.value!.path, filename: "profile.jpg"),
        ));
        response = await ApiProvider().requestMultipartApi(
          context,
          WebApiConstant.API_URL_ADD_FAMILY_MEMBER,
          formData,
          userAccessToken!,
        );
      } else {
        // Don't send profile_photo: null — omit the field when no photo.
        response = await ApiProvider().addFamilyMemberAPI(
          context,
          WebApiConstant.API_URL_ADD_FAMILY_MEMBER,
          dictParameter,
          userAccessToken!,
        );
      }

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        final data = (response is dio.Response) ? response.data : response;
        if (data != null && data is Map) {
          if (data['error'] != true && data['error_code'] == 0) {
            AppToast.showToast(msg: data['message'] ?? 'Family member added successfully.');
            onSuccess();
          } else {
            AppToast.showToast(msg: data['message']?.toString() ?? '');
          }
        } else {
          PrintLog.printLog("Unexpected response format: $response");
          AppToast.showToast(msg: WebApiConstant.ApiError);
        }
      } else {
        AppToast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      AppToast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  Future<void> updateFamilyMemberAPI(BuildContext context, VoidCallback onSuccess) async {
    if (!_validate()) return;
    if (currentPatientId == null) return;

    try {
      /* final storage = StorageService();
      String accessType = await storage.getString(StorageService.accessType);
      if (accessType == "2") {
        Get.snackbar(
          "Access Restricted",
          "You don't have permission to edit family members.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      } */

      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final homeAddress = HomeAddress(
        address: addressLineCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: selectedState.value.trim(),
        postCode: postCodeCtrl.text.trim(),
      ).display;

      final Map<String, dynamic> dictParameter = {
        "patient_id": currentPatientId,
        "full_name": fullNameCtrl.text.trim(),
        "mobile_number": mobileNumberCtrl.text.trim(),
        "abha_number": abhaNumberCtrl.text.trim(),
        "date_of_birth": DateFormat('yyyy-MM-dd').format(selectedDob.value!),
        "gender": selectedGender.value.toLowerCase(),
        "nationality": selectedCountry.value?.id,
        "relation": selectedRelationModel.value?.code,
        "blood_group": bloodGroup.value.toLowerCase() == 'unknown'
            ? 'unknown'
            : bloodGroup.value,
        "height": double.tryParse(heightCtrl.text.trim()) ?? 0,
        "weight": double.tryParse(weightCtrl.text.trim()) ?? 0,
        "marital_status": maritalStatus.value.toLowerCase(),
        "occupation": selectedOccupationModel.value?.code ?? occupationCtrl.text.trim(),
        "chronic_disease": hasChronicDisease.value,
        "physically_handicapped": isPhysicallyHandicapped.value,
        "disability_type": isPhysicallyHandicapped.value ? (selectedDisabilityTypeModel.value?.code ?? disabilityTypeCtrl.text.trim()) : "",
        "organ_donor": isOrganDonor.value,
        "home_address": homeAddress,
        "contact_name": contactNameCtrl.text.trim(),
        "contact_relation": contactRelation.value.toLowerCase(),
        "contact_mobile": contactMobileCtrl.text.trim(),
        "insurance_provider": insuranceProviderCtrl.text.trim(),
        "policy_number": policyNumberCtrl.text.trim(),
        // API expects JSON arrays (same as Postman), not jsonEncode strings.
        "allergies": selectedAllergies.toList(),
        "medications": selectedMedications.toList(),
        "risk_factors": selectedRiskFactors.toList(),
      };

      dynamic response;
      if (profileImage.value != null) {
        final formData = dio.FormData.fromMap(dictParameter);
        formData.files.add(MapEntry(
          "profile_photo",
          await dio.MultipartFile.fromFile(profileImage.value!.path, filename: "profile_update.jpg"),
        ));
        response = await ApiProvider().requestMultipartApi(
          context,
          WebApiConstant.API_URL_UPDATE_FAMILY_MEMBER,
          formData,
          userAccessToken!,
        );
      } else {
        dictParameter["profile_photo"] = null;
        response = await ApiProvider().updateFamilyMemberAPI(
          context,
          WebApiConstant.API_URL_UPDATE_FAMILY_MEMBER,
          dictParameter,
          userAccessToken!,
        );
      }

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        final data = (response is dio.Response) ? response.data : response;
        if (data != null && data is Map) {
          if (data['error'] != true && data['error_code'] == 0) {
            AppToast.showToast(msg: data['message'] ?? 'Family member updated successfully.');
            onSuccess();
          } else {
            AppToast.showToast(msg: data['message']?.toString() ?? '');
          }
        } else {
          PrintLog.printLog("Unexpected response format: $response");
          AppToast.showToast(msg: WebApiConstant.ApiError);
        }
      } else {
        AppToast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      AppToast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  Future<void> giveAccessAPI(BuildContext context, String patientId, {String type = "give"}) async {
    try {
      isLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().giveAccessAPI(
        context,
        WebApiConstant.API_URL_GIVE_ACCESS,
        {
          "patient_id": patientId,
          "type": type,
        },
        userAccessToken ?? '',
      );

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          AppToast.showToast(
            msg: response['message'] ??
                (type == 'revoke'
                    ? 'Access revoked successfully'
                    : 'Access given successfully'),
          );
          final granted = type != 'revoke';
          final i = familyMemberList.indexWhere((e) => e.patientId == patientId);
          if (i >= 0) {
            familyMemberList[i].accessGiven = granted;
            familyMemberList[i].accessType = granted ? 2 : 0;
            if (!granted) {
              familyMemberList[i].fullAccess = false;
              familyMemberList[i].emergencyOnly = false;
            }
            familyMemberList.refresh();
          }
          final detail = familyMemberDetail.value;
          if (detail?.patientId == patientId) {
            detail!.accessGiven = granted;
            detail.accessType = granted ? 2 : 0;
            if (!granted) {
              detail.fullAccess = false;
              detail.emergencyOnly = false;
              fullAccess.value = false;
              emergencyOnly.value = false;
            }
            familyMemberDetail.refresh();
          }
          await getFamilyMemberDetailAPI(context, patientId);
          await getFamilyMemberListAPI(context);
          if (Get.isRegistered<HomeController>()) {
            await Get.find<HomeController>().fetchFamilyMembers();
          }
        } else {
          AppToast.showToast(msg: response['message'] ?? 'Failed to give access');
        }
      }

    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception giveAccessAPI: $e");
    }
  }

  /// GET /patients/parent-permission/ — child's pending request.
  Future<ParentPermission?> fetchParentPermission(BuildContext? context) async {
    try {
      userAccessToken = await StorageService().getString(StorageService.token);
      final response = await ApiProvider().requestGetForApi(
        context ?? Get.context,
        WebApiConstant.API_URL_PARENT_PERMISSION,
        {},
        userAccessToken ?? '',
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data is Map) {
        final raw = Map<String, dynamic>.from(response.data as Map);
        if (raw['error'] == true) return null;
        final data = raw['data'] is Map ? raw['data'] : raw;
        if (data is Map) {
          return ParentPermission.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      PrintLog.printLog('fetchParentPermission: $e');
    }
    return null;
  }

  /// POST /patients/parent-permission/ { action: grant|deny }
  Future<bool> respondParentPermission({
    required BuildContext context,
    required String action,
  }) async {
    try {
      isLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);
      final response = await ApiProvider().requestPostForApi(
        context,
        WebApiConstant.API_URL_PARENT_PERMISSION,
        {'action': action},
        userAccessToken ?? '',
      );
      isLoading.value = false;
      if (response != null && response.data is Map) {
        final raw = Map<String, dynamic>.from(response.data as Map);
        AppToast.showToast(
          msg: raw['message']?.toString() ??
              (action == 'grant'
                  ? 'Permission granted.'
                  : 'Permission declined.'),
        );
        final ok = raw['error'] != true;
        if (ok && Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().loadParentPermission();
        }
        return ok;
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog('respondParentPermission: $e');
      AppToast.showToast(msg: WebApiConstant.ApiError);
    }
    return false;
  }

  @override
  void onClose() {
    fullNameCtrl.dispose();
    mobileNumberCtrl.dispose();
    abhaNumberCtrl.dispose();
    dobCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    occupationCtrl.dispose();
    disabilityTypeCtrl.dispose();
    medicationInputCtrl.dispose();
    addressLineCtrl.dispose();
    cityCtrl.dispose();
    postCodeCtrl.dispose();
    contactNameCtrl.dispose();
    contactMobileCtrl.dispose();
    insuranceProviderCtrl.dispose();
    policyNumberCtrl.dispose();
    super.onClose();
  }
}
