import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../DataProvider/api_provider.dart';
import 'package:digitalhealth/DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import 'package:digitalhealth/app/core/Util/Print/print_log.dart';
import 'package:digitalhealth/app/data/models/family_member_model.dart';


/// Master country list ka model
class CountryModel {
  final int id;
  final String name;
  final String flagEmoji;

  CountryModel({required this.id, required this.name, required this.flagEmoji});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      flagEmoji: json['flag_emoji']?.toString() ?? '',
    );
  }
}

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

class FamilyMemberController extends GetxController {
  String? userAccessToken;
  RxBool isLoading = false.obs;

  // Mode: Add or Update
  RxBool isUpdateMode = false.obs;
  String? currentPatientId;

  // ---------------- Image Picker ----------------
  Rx<File?> profileImage = Rx<File?>(null);
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        profileImage.value = File(image.path);
      }
    } catch (e) {
      PrintLog.printLog("Pick Image Error: $e");
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
      
      // If fullAccess is turned on, emergencyOnly should probably be turned off or vice versa 
      // depending on business logic. For now, I'll just send what's toggled.
      final newFullAccess = isFullAccess ? value : fullAccess.value;
      final newEmergencyOnly = !isFullAccess ? value : emergencyOnly.value;

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
        Fluttertoast.showToast(msg: response['message'] ?? "Access updated");
      } else {
        Fluttertoast.showToast(msg: response?['message'] ?? "Failed to update access");
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Access Control Exception: $e");
    }
  }

  // ---------------- Personal ----------------
  final fullNameCtrl = TextEditingController();
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

  // ---------------- Medical ----------------
  RxString bloodGroup = ''.obs;
  final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', "Don't Know"];
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

  final medicationInputCtrl = TextEditingController();
  RxList<String> selectedMedications = <String>[].obs;

  void toggleAllergy(String tag) {
    if (selectedAllergies.contains(tag)) {
      selectedAllergies.remove(tag);
    } else {
      selectedAllergies.add(tag);
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
  final cityCtrl = TextEditingController();
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
  final contactRelations = ['Parent', 'Sibling', 'Spouse', 'Friend', 'Other'];
  final contactMobileCtrl = TextEditingController();

  final insuranceProviderCtrl = TextEditingController();
  final policyNumberCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);
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
          Fluttertoast.showToast(msg: response['message']?.toString() ?? '');
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
        } else {
          Fluttertoast.showToast(msg: response['message']?.toString() ?? '');
        }
      } else {
        PrintLog.printLog("Unexpected response (not JSON): $response");
        Fluttertoast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isCountryLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
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

  void clearFields() {
    isUpdateMode.value = false;
    currentPatientId = null;
    familyMemberDetail.value = null;
    profileImage.value = null;

    fullNameCtrl.clear();
    dobCtrl.clear();
    selectedDob.value = null;
    selectedGender.value = '';
    selectedRelation.value = '';
    selectedRelationModel.value = null;
    selectedCountry.value = null;

    bloodGroup.value = '';
    heightCtrl.clear();
    weightCtrl.clear();
    maritalStatus.value = '';
    occupationCtrl.clear();
    selectedOccupationModel.value = null;

    hasChronicDisease.value = false;
    isPhysicallyHandicapped.value = false;
    disabilityTypeCtrl.clear();
    isOrganDonor.value = false;

    selectedAllergies.clear();
    selectedMedications.clear();
    medicationInputCtrl.clear();

    cityCtrl.clear();
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
          final List list = response['data']?['family_members'] ?? [];
          familyMemberList.value = list.map((e) => FamilyMember.fromJson(e)).toList();
        } else {
          Fluttertoast.showToast(msg: response['message']?.toString() ?? '');
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
          }
        } else {
          Fluttertoast.showToast(msg: response['message']?.toString() ?? '');
        }
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Detail Exception: $e");
    }
  }

  Future<void> deleteFamilyMember(BuildContext context, String patientId, VoidCallback onSuccess) async {
    try {
      // final Map<String, dynamic> dictParameter = {
      //   "full_name": fullNameCtrl.text.trim(),
      //
      // }

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
          Fluttertoast.showToast(msg: response['message'] ?? 'Family member deleted successfully.');
          onSuccess();
        } else {
          Fluttertoast.showToast(msg: response['message']?.toString() ?? '');
        }
      } else {
        Fluttertoast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Delete Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  void _populateFields(FamilyMember member) {
    fullNameCtrl.text = member.fullName ?? '';
    if (member.dateOfBirth != null) {
      selectedDob.value = DateFormat('yyyy-MM-dd').parse(member.dateOfBirth!);
      dobCtrl.text = DateFormat('dd/MM/yyyy').format(selectedDob.value!);
    }
    selectedGender.value = toBeginningOfSentenceCase(member.gender) ?? '';
    
    if (member.relation != null) {
      selectedRelationModel.value = relationList.firstWhereOrNull((r) => r.id == member.relation?.id);
    }

    if (member.nationality != null) {
      selectedCountry.value = countryList.firstWhereOrNull((c) => c.id == member.nationality?.id);
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
    isOrganDonor.value = member.medical?.organDonor ?? false;

    selectedAllergies.value = member.medical?.allergies?.map((e) => e.allergyName ?? '').toList() ?? [];
    selectedMedications.value = member.medical?.currentMedications ?? [];

    if (member.homeAddress != null) {
      final parts = member.homeAddress!.split(', ');
      if (parts.isNotEmpty) cityCtrl.text = parts[0];
      if (parts.length > 1) selectedState.value = parts[1];
    }

    contactNameCtrl.text = member.emergencyContact?.contactName ?? '';
    if (member.emergencyContact?.relation != null) {
      selectedContactRelationModel.value = relationList.firstWhereOrNull(
          (r) => r.name.toLowerCase() == member.emergencyContact?.relation?.toLowerCase() || 
                 r.code.toLowerCase() == member.emergencyContact?.relation?.toLowerCase());
      contactRelation.value = selectedContactRelationModel.value?.name ?? toBeginningOfSentenceCase(member.emergencyContact?.relation) ?? '';
    }
    contactMobileCtrl.text = member.emergencyContact?.phoneNumber ?? '';

    insuranceProviderCtrl.text = member.insurance?.provider ?? '';
    policyNumberCtrl.text = member.insurance?.policyNumber ?? '';
  }

  bool _validate() {
    if (fullNameCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter full name');
      return false;
    }
    if (selectedDob.value == null) {
      Fluttertoast.showToast(msg: 'Please select date of birth');
      return false;
    }
    if (selectedGender.value.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select gender');
      return false;
    }
    if (selectedRelationModel.value == null) {
      Fluttertoast.showToast(msg: 'Please select relation');
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
      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final homeAddress = [cityCtrl.text.trim(), selectedState.value]
          .where((e) => e.isNotEmpty)
          .join(', ');

      final Map<String, dynamic> dictParameter = {
        "full_name": fullNameCtrl.text.trim(),
        "date_of_birth": DateFormat('yyyy-MM-dd').format(selectedDob.value!),
        "gender": selectedGender.value.toLowerCase(),
        "nationality": selectedCountry.value?.id,
        "relation": selectedRelationModel.value?.code,
        "blood_group": bloodGroup.value,
        "height": double.tryParse(heightCtrl.text.trim()) ?? 0,
        "weight": double.tryParse(weightCtrl.text.trim()) ?? 0,
        "marital_status": maritalStatus.value.toLowerCase(),
        "occupation": selectedOccupationModel.value?.code ?? occupationCtrl.text.trim(),
        "chronic_disease": hasChronicDisease.value,
        "physically_handicapped": isPhysicallyHandicapped.value,
        "disability_type": isPhysicallyHandicapped.value ? disabilityTypeCtrl.text.trim() : "",
        "organ_donor": isOrganDonor.value,
        "home_address": homeAddress,
        "contact_name": contactNameCtrl.text.trim(),
        "contact_relation": contactRelation.value.toLowerCase(),
        "contact_mobile": contactMobileCtrl.text.trim(),
        "insurance_provider": insuranceProviderCtrl.text.trim(),
        "policy_number": policyNumberCtrl.text.trim(),
        "allergies": selectedAllergies.toList(),
        "medications": selectedMedications.toList(),
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
        dictParameter["profile_photo"] = null;
        response = await ApiProvider().loginApi(
          context,
          WebApiConstant.API_URL_ADD_FAMILY_MEMBER,
          dictParameter,
          userAccessToken!,
        );
      }

      isLoading.value = false;
      // ... handle response
      PrintLog.printLog(response);

      if (response != null) {
        final data = (response is dio.Response) ? response.data : response;
        if (data != null && data is Map) {
          if (data['error'] != true && data['error_code'] == 0) {
            Fluttertoast.showToast(msg: data['message'] ?? 'Family member added successfully.');
            onSuccess();
          } else {
            Fluttertoast.showToast(msg: data['message']?.toString() ?? '');
          }
        } else {
          PrintLog.printLog("Unexpected response format: $response");
          Fluttertoast.showToast(msg: WebApiConstant.ApiError);
        }
      } else {
        Fluttertoast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  Future<void> updateFamilyMemberAPI(BuildContext context, VoidCallback onSuccess) async {
    if (!_validate()) return;
    if (currentPatientId == null) return;

    try {
      isLoading.value = true;
      userAccessToken = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final homeAddress = [cityCtrl.text.trim(), selectedState.value]
          .where((e) => e.isNotEmpty)
          .join(', ');

      final Map<String, dynamic> dictParameter = {
        "patient_id": currentPatientId,
        "full_name": fullNameCtrl.text.trim(),
        "date_of_birth": DateFormat('yyyy-MM-dd').format(selectedDob.value!),
        "gender": selectedGender.value.toLowerCase(),
        "nationality": selectedCountry.value?.id,
        "relation": selectedRelationModel.value?.code,
        "blood_group": bloodGroup.value,
        "height": double.tryParse(heightCtrl.text.trim()) ?? 0,
        "weight": double.tryParse(weightCtrl.text.trim()) ?? 0,
        "marital_status": maritalStatus.value.toLowerCase(),
        "occupation": selectedOccupationModel.value?.code ?? occupationCtrl.text.trim(),
        "chronic_disease": hasChronicDisease.value,
        "physically_handicapped": isPhysicallyHandicapped.value,
        "disability_type": isPhysicallyHandicapped.value ? disabilityTypeCtrl.text.trim() : "",
        "organ_donor": isOrganDonor.value,
        "home_address": homeAddress,
        "contact_name": contactNameCtrl.text.trim(),
        "contact_relation": contactRelation.value.toLowerCase(),
        "contact_mobile": contactMobileCtrl.text.trim(),
        "insurance_provider": insuranceProviderCtrl.text.trim(),
        "policy_number": policyNumberCtrl.text.trim(),
        "allergies": selectedAllergies.toList(),
        "medications": selectedMedications.toList(),
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
            Fluttertoast.showToast(msg: data['message'] ?? 'Family member updated successfully.');
            onSuccess();
          } else {
            Fluttertoast.showToast(msg: data['message']?.toString() ?? '');
          }
        } else {
          PrintLog.printLog("Unexpected response format: $response");
          Fluttertoast.showToast(msg: WebApiConstant.ApiError);
        }
      } else {
        Fluttertoast.showToast(msg: WebApiConstant.ApiError);
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  @override
  void onClose() {
    fullNameCtrl.dispose();
    dobCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    occupationCtrl.dispose();
    disabilityTypeCtrl.dispose();
    medicationInputCtrl.dispose();
    cityCtrl.dispose();
    contactNameCtrl.dispose();
    contactMobileCtrl.dispose();
    insuranceProviderCtrl.dispose();
    policyNumberCtrl.dispose();
    super.onClose();
  }
}
