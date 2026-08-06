import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:healaura/app/data/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import 'package:healaura/app/core/Util/Print/print_log.dart';
import '../../../core/Util/image_pick_helper.dart';
import '../../../core/theme/app_colors.dart';

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


/// Single controller — PersonalInfo, MedicalInfo aur EmergencyInfo
/// teeno screens isi ek controller ko use karenge (Get.put once, phir Get.find).
class ProfileController extends GetxController {
  bool _isDisposed = false;
  String? userAccessToken;

  RxBool isLoading = false.obs;

  // ==================================================================
  // ---------------------  PERSONAL INFO (Step 1)  ------------------
  // ==================================================================
  final fullNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final dobCtrl = TextEditingController(); // display ke liye: dd / MM / yyyy
  Rx<DateTime?> selectedDob = Rx<DateTime?>(null);

  /// Reactive display name for Profile UI (TextEditingController alone won't refresh Obx).
  RxString profileDisplayName = ''.obs;

  RxString selectedGender = ''.obs; // API me lowercase jayega: male/female/other
  RxInt age = 0.obs;
  RxString mobileNumber = ''.obs;

  void setProfileName(String? raw) {
    final cleaned = _parseName(raw);
    fullNameCtrl.text = cleaned;
    profileDisplayName.value = cleaned;
  }

  static String _parseName(dynamic raw) {
    if (raw == null) return '';
    if (raw is Map) {
      return (raw['full_name'] ?? raw['name'] ?? raw['value'] ?? '')
          .toString()
          .trim();
    }
    var s = raw.toString().trim();
    // Guard against accidental Map.toString() leakage
    if (s.startsWith('{') && s.contains(':')) return '';
    return s;
  }

  final genders = ['Male', 'Female', 'Other'];

  // ------------------ Profile photo ------------------
  Rx<File?> profileImage = Rx<File?>(null);
  RxString profilePhotoUrl = ''.obs;

  static String _normalizePhotoUrl(String? raw) {
    var url = (raw ?? '').trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return '';
    if (url.startsWith('//')) {
      url = 'http:$url';
    }
    if (url.startsWith('/')) {
      url = 'http://medconnect.airainnovations.com$url';
    }
    // Keep server URL as-is (media is served over http).
    return url;
  }

  Future<void> pickProfileImage(ImageSource source) async {
    try {
      final file = await ImagePickHelper.pick(
        source: source,
        imageQuality: 70,
      );
      if (file != null) {
        profileImage.value = file;
      }
    } catch (e) {
      PrintLog.printLog('Pick profile image error: $e');
      Fluttertoast.showToast(msg: 'Could not pick image');
    }
  }

  void showProfilePhotoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(
          listTileTheme: const ListTileThemeData(
            textColor: Colors.black,
            iconColor: Colors.black,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                textColor: Colors.black,
                iconColor: Colors.black,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.teal),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                textColor: Colors.black,
                iconColor: Colors.black,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.teal),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickProfileImage(ImageSource.gallery);
                },
              ),
              if (profileImage.value != null ||
                  profilePhotoUrl.value.isNotEmpty)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.statusRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.statusRed),
                  ),
                  title: const Text('Remove photo',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusRed)),
                  onTap: () {
                    Navigator.pop(context);
                    profileImage.value = null;
                    profilePhotoUrl.value = '';
                  },
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ------------------ Master Relation List (API se) ------------------
  RxBool isRelationLoading = false.obs;
  RxList<RelationModel> relationList = <RelationModel>[].obs;
  Rx<RelationModel?> selectedEmergencyRelationModel = Rx<RelationModel?>(null);

  /// Filtered and sorted list for Emergency Contacts
  List<RelationModel> get filteredEmergencyRelations {
    // Definining categories to include
    final spouseKeywords = ['spouse', 'husband', 'wife'];
    final parentKeywords = ['parent', 'mother', 'father'];
    final siblingKeywords = ['sibling', 'brother', 'sister'];
    final friendKeywords = ['friend'];
    final otherKeywords = ['other', 'others'];

    List<RelationModel> filtered = relationList.where((r) {
      final name = r.name.toLowerCase();
      final code = r.code.toLowerCase();
      
      return spouseKeywords.any((k) => name.contains(k) || code.contains(k)) ||
             parentKeywords.any((k) => name.contains(k) || code.contains(k)) ||
             siblingKeywords.any((k) => name.contains(k) || code.contains(k)) ||
             friendKeywords.any((k) => name.contains(k) || code.contains(k)) ||
             otherKeywords.any((k) => name.contains(k) || code.contains(k));
    }).toList();

    // Custom Sorting: Spouse -> Parent -> Sibling -> Friend -> Other
    filtered.sort((a, b) {
      int getOrder(RelationModel r) {
        final n = r.name.toLowerCase();
        final c = r.code.toLowerCase();
        if (spouseKeywords.any((k) => n.contains(k) || c.contains(k))) return 1;
        if (parentKeywords.any((k) => n.contains(k) || c.contains(k))) return 2;
        if (siblingKeywords.any((k) => n.contains(k) || c.contains(k))) return 3;
        if (friendKeywords.any((k) => n.contains(k) || c.contains(k))) return 4;
        return 5; // Other
      }
      return getOrder(a).compareTo(getOrder(b));
    });

    return filtered;
  }

  Future<void> getAllMasterDataAPI(BuildContext context) async {
    try {
      isRelationLoading.value = true;
      isCountryLoading.value = true;
      isOccupationLoading.value = true;
      isDisabilityTypeLoading.value = true;
      
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getAllMasterDataAPI(
        context,
        WebApiConstant.API_URL_MASTER_ALL,
        {},
        userAccessToken ?? '',
      );

      isRelationLoading.value = false;
      isCountryLoading.value = false;
      isOccupationLoading.value = false;
      isDisabilityTypeLoading.value = false;

      if (_isDisposed) return;
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

            // Occupations
            final List occupations = data['occupations'] ?? [];
            occupationList.value = occupations.map((e) => OccupationModel.fromJson(e)).toList();

            // Disability Types
            final List disabilities = data['disability_types'] ?? [];
            disabilityTypeList.value = disabilities.map((e) => DisabilityTypeModel.fromJson(e)).toList();

            // Sync selections if needed
            if (emergencyRelation.value.isNotEmpty) {
              selectedEmergencyRelationModel.value = relationList.firstWhereOrNull(
                (r) => r.code.toLowerCase() == emergencyRelation.value.toLowerCase() ||
                r.name.toLowerCase() == emergencyRelation.value.toLowerCase(),
              );
            }

            if (selectedNationalityId.value != null) {
              selectedCountry.value = countryList.firstWhereOrNull(
                (c) => c.id == selectedNationalityId.value,
              );
            }

            if (occupationCtrl.text.isNotEmpty) {
              selectedOccupationModel.value = occupationList.firstWhereOrNull(
                (o) => o.code.toLowerCase() == occupationCtrl.text.toLowerCase() ||
                o.name.toLowerCase() == occupationCtrl.text.toLowerCase(),
              );
            }

            if (disabilityTypeCtrl.text.isNotEmpty) {
              selectedDisabilityTypeModel.value = disabilityTypeList.firstWhereOrNull(
                (d) => d.code.toLowerCase() == disabilityTypeCtrl.text.toLowerCase() ||
                d.name.toLowerCase() == disabilityTypeCtrl.text.toLowerCase(),
              );
            }
          }
        }
      }
    } catch (e) {
      isRelationLoading.value = false;
      isCountryLoading.value = false;
      isOccupationLoading.value = false;
      isDisabilityTypeLoading.value = false;
      PrintLog.printLog("Exception getAllMasterDataAPI: $e");
    }
  }

  Future<void> getMasterRelationAPI(BuildContext context) async {
    try {
      isRelationLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getMasterRelationAPI(
        context,
        WebApiConstant.API_URL_MASTER_RELATIONS,
        {},
        userAccessToken ?? '',
      );

      isRelationLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data']?['relations'] ?? [];
          relationList.value = list.map((e) => RelationModel.fromJson(e)).toList();

          // Sync with loaded profile if needed
          if (emergencyRelation.value.isNotEmpty) {
            selectedEmergencyRelationModel.value = relationList.firstWhereOrNull(
                  (r) => r.code.toLowerCase() == emergencyRelation.value.toLowerCase() ||
                  r.name.toLowerCase() == emergencyRelation.value.toLowerCase(),
            );
          }
        }
      }
    } catch (e) {
      isRelationLoading.value = false;
      PrintLog.printLog("Exception Relation: $e");
    }
  }

  // ------------------ Master Country List (API se) ------------------
  RxBool isCountryLoading = false.obs;
  RxList<CountryModel> countryList = <CountryModel>[].obs;
  Rx<CountryModel?> selectedCountry = Rx<CountryModel?>(null);

  Future<void> getMasterCountryAPI(BuildContext context) async {
    try {
      isCountryLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);


      final response = await ApiProvider().getMasterCountryAPI(
        context,
        WebApiConstant.API_URL_MASTER_COUNTRY,
        {},
        userAccessToken ?? '',
      );

      isCountryLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data'] ?? [];
          countryList.value = list.map((e) => CountryModel.fromJson(e)).toList();

          // Agar profile me pehle se koi nationality id saved hai to usko yaha select kar do
          if (selectedNationalityId.value != null) {
            selectedCountry.value = countryList.firstWhereOrNull(
                  (c) => c.id == selectedNationalityId.value,
            );
          }
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? '');
        }
      }
    } catch (e) {
      isCountryLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  void onCountrySelected(CountryModel? country) {
    selectedCountry.value = country;
    selectedNationalityId.value = country?.id;
  }

  Rx<int?> selectedNationalityId = Rx<int?>(null);

  // ------------------ Master Occupation List (API se) ------------------
  RxBool isOccupationLoading = false.obs;
  RxList<OccupationModel> occupationList = <OccupationModel>[].obs;
  Rx<OccupationModel?> selectedOccupationModel = Rx<OccupationModel?>(null);

  Future<void> getMasterOccupationAPI(BuildContext context) async {
    try {
      isOccupationLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getMasterOccupationAPI(
        context,
        WebApiConstant.API_URL_MASTER_OCCUPATIONS,
        {},
        userAccessToken ?? '',
      );

      isOccupationLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data']?['occupations'] ?? [];
          occupationList.value = list.map((e) => OccupationModel.fromJson(e)).toList();

          // Sync with loaded profile
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

  // ------------------ Master Disability Type List (API se) ------------------
  RxBool isDisabilityTypeLoading = false.obs;
  RxList<DisabilityTypeModel> disabilityTypeList = <DisabilityTypeModel>[].obs;
  Rx<DisabilityTypeModel?> selectedDisabilityTypeModel = Rx<DisabilityTypeModel?>(null);

  Future<void> getMasterDisabilityTypeAPI(BuildContext context) async {
    try {
      isDisabilityTypeLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getMasterDisabilityTypeAPI(
        context,
        WebApiConstant.API_URL_MASTER_DISABILITY_TYPES,
        {},
        userAccessToken ?? '',
      );

      isDisabilityTypeLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null && response is Map) {
        if (response['error'] != true && response['error_code'] == 0) {
          final List list = response['data']?['disability_types'] ?? [];
          disabilityTypeList.value = list.map((e) => DisabilityTypeModel.fromJson(e)).toList();

          // Sync with loaded profile
          if (disabilityTypeCtrl.text.isNotEmpty) {
            selectedDisabilityTypeModel.value = disabilityTypeList.firstWhereOrNull(
                  (d) => d.code.toLowerCase() == disabilityTypeCtrl.text.toLowerCase() ||
                  d.name.toLowerCase() == disabilityTypeCtrl.text.toLowerCase(),
            );
          }
        }
      }
    } catch (e) {
      isDisabilityTypeLoading.value = false;
      PrintLog.printLog("Exception DisabilityType: $e");
    }
  }

  // ==================================================================
  // ---------------------  MEDICAL INFO (Step 2)  --------------------
  // ==================================================================
  RxString bloodGroup = ''.obs;
  RxString heightUnit = 'cm'.obs;
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  RxString maritalStatus = ''.obs; // single/married/divorced/widowed
  final occupationCtrl = TextEditingController();

  RxBool hasChronicDisease = false.obs;
  RxBool isPhysicallyHandicapped = false.obs;
  final disabilityTypeCtrl = TextEditingController();
  RxBool isOrganDonor = false.obs;

  final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final maritalStatusOptions = ['Single', 'Married', 'Divorced', 'Widowed'];

  final allergyTags = ['Penicillin', 'Peanuts', 'Latex', 'Dust', 'Dairy'];
  RxList<String> selectedAllergies = <String>[].obs;

  // medications free-text chips (fixed list nahi hai, user khud add karega)
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

  // ==================================================================
  // -------------------  EMERGENCY INFO (Step 3)  --------------------
  // ==================================================================
  final emergencyNameCtrl = TextEditingController();
  final emergencyMobileCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  RxString selectedState = ''.obs;

  RxString emergencyRelation = ''.obs; // spouse/parent/sibling/friend/other
  final emergencyRelations = ['Spouse', 'Parent', 'Sibling', 'Friend', 'Other'];
  final states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
    'Uttarakhand', 'West Bengal', 'Andaman and Nicobar Islands',
    'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 'Delhi',
    'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry'
  ];

  RxBool showInsurance = false.obs;
  final insuranceProviderCtrl = TextEditingController();
  final policyNumberCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    await _loadToken();
    if (Get.context != null) {
      // Call the consolidated Master API
      await getAllMasterDataAPI(Get.context!);
      
      // Load profile if token is available
      if (userAccessToken != null && userAccessToken!.isNotEmpty) {
        getPatientProfileAPI(Get.context!);
      }
    }
  }

  Future<void> _loadToken() async {
    userAccessToken = await StorageService().getString(StorageService.token);
  }

  // ==================================================================
  // ---------------------  API : get-profile  ---------------------
  // ==================================================================
  Future<void> getPatientProfileAPI(BuildContext context) async {
    try {
      isLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getPatientProfileAPI(
        context,
        WebApiConstant.API_URL_PATIENT_PROFILE,
        {},
        userAccessToken ?? '',
      );

      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          final data = response['data'];
          if (data != null) {
            if (_isDisposed) return;
            // Personal Info
            setProfileName(data['full_name'] ?? data['name']);
            emailCtrl.text = data['email']?.toString() ?? '';
            mobileNumber.value = data['mobile_number']?.toString() ?? '';
            age.value = data['age'] ?? 0;
            final photo = _normalizePhotoUrl(
              data['profile_photo']?.toString() ??
                  data['profile_picture']?.toString() ??
                  data['photo']?.toString() ??
                  '',
            );
            if (profileImage.value == null) {
              profilePhotoUrl.value = photo;
            }
            if (data['date_of_birth'] != null) {
              selectedDob.value = DateTime.tryParse(data['date_of_birth'].toString());
              if (selectedDob.value != null) {
                if (_isDisposed) return;
                dobCtrl.text = DateFormat('dd / MM / yyyy').format(selectedDob.value!);

                // Calculate age locally if 0
                if (age.value == 0) {
                  DateTime now = DateTime.now();
                  int calculatedAge = now.year - selectedDob.value!.year;
                  if (now.month < selectedDob.value!.month ||
                      (now.month == selectedDob.value!.month && now.day < selectedDob.value!.day)) {
                    calculatedAge--;
                  }
                  age.value = calculatedAge;
                }
              }
            }
            // Handle Gender (String or Map)
            var genderData = data['gender'];
            String genderVal = '';
            if (genderData is Map) {
              genderVal = genderData['name']?.toString() ?? '';
            } else {
              genderVal = genderData?.toString() ?? '';
            }

            if (genderVal.isNotEmpty) {
              selectedGender.value = genderVal[0].toUpperCase() + genderVal.substring(1).toLowerCase();
            }

            if (data['nationality'] != null) {
              selectedNationalityId.value = data['nationality']['id'];
              // Agar country list pehle se loaded hai to select kar lo
              if (countryList.isNotEmpty) {
                selectedCountry.value = countryList.firstWhereOrNull(
                      (c) => c.id == selectedNationalityId.value,
                );
              }
            }

            // Medical Info
            // Handle Blood Group (String or Map)
            var bgData = data['blood_group'];
            if (bgData is Map) {
              bloodGroup.value = bgData['name']?.toString() ?? '';
            } else {
              bloodGroup.value = bgData?.toString() ?? '';
            }

            heightCtrl.text = data['height']?.toString() ?? '';
            weightCtrl.text = data['weight']?.toString() ?? '';

            final medical = data['medical'];
            if (medical != null) {
              hasChronicDisease.value = medical['chronic_disease'] == true;
              isPhysicallyHandicapped.value = medical['physically_handicapped'] == true;
              
              // Handle Disability Type (String or Map)
              var disData = medical['disability_type'];
              if (disData is Map) {
                if (!_isDisposed) disabilityTypeCtrl.text = disData['name']?.toString() ?? '';
                final disCode = disData['code']?.toString() ?? '';
                if (disabilityTypeList.isNotEmpty) {
                  selectedDisabilityTypeModel.value = disabilityTypeList.firstWhereOrNull(
                        (d) => d.code.toLowerCase() == disCode.toLowerCase() ||
                        d.name.toLowerCase() == disabilityTypeCtrl.text.toLowerCase(),
                  );
                }
              } else {
                if (!_isDisposed) disabilityTypeCtrl.text = disData?.toString() ?? '';
                if (disabilityTypeList.isNotEmpty) {
                  selectedDisabilityTypeModel.value = disabilityTypeList.firstWhereOrNull(
                        (d) => d.code.toLowerCase() == disabilityTypeCtrl.text.toLowerCase() ||
                        d.name.toLowerCase() == disabilityTypeCtrl.text.toLowerCase(),
                  );
                }
              }

              isOrganDonor.value = medical['organ_donor'] == true;

              final List? allergies = medical['allergies'];
              if (allergies != null) {
                selectedAllergies.value = allergies.map((e) => e['allergy_name'].toString()).toList();
              }

              final List? medications = medical['current_medications'];
              if (medications != null) {
                selectedMedications.value = medications.map((e) => e.toString()).toList();
              }
            }

            maritalStatus.value = (data['marital_status']?.toString() ?? '').capitalizeFirst ?? '';
            
            // Handle Occupation (String or Map)
            var occData = data['occupation'];
            if (occData is Map) {
              if (!_isDisposed) occupationCtrl.text = occData['name']?.toString() ?? '';
              final occCode = occData['code']?.toString() ?? '';
              if (occupationList.isNotEmpty) {
                selectedOccupationModel.value = occupationList.firstWhereOrNull(
                      (o) => o.code.toLowerCase() == occCode.toLowerCase() ||
                      o.name.toLowerCase() == occupationCtrl.text.toLowerCase(),
                );
              }
            } else {
              if (!_isDisposed) occupationCtrl.text = occData?.toString() ?? '';
              if (occupationList.isNotEmpty) {
                selectedOccupationModel.value = occupationList.firstWhereOrNull(
                      (o) => o.code.toLowerCase() == occupationCtrl.text.toLowerCase() ||
                      o.name.toLowerCase() == occupationCtrl.text.toLowerCase(),
                );
              }
            }

            // Emergency Info
            final emergency = data['emergency_contact'];
            if (emergency != null) {
              if (!_isDisposed) {
                emergencyNameCtrl.text = emergency['contact_name']?.toString() ?? '';
                emergencyMobileCtrl.text = emergency['phone_number']?.toString() ?? '';
              }
              
              // Handle Relation (String or Map)
              var relData = emergency['relation'];
              String relCode = '';
              if (relData is Map) {
                emergencyRelation.value = (relData['name']?.toString() ?? '').capitalizeFirst ?? '';
                relCode = relData['code']?.toString() ?? '';
              } else {
                emergencyRelation.value = (relData?.toString() ?? '').capitalizeFirst ?? '';
                relCode = emergencyRelation.value;
              }
              
              if (relationList.isNotEmpty) {
                selectedEmergencyRelationModel.value = relationList.firstWhereOrNull(
                      (r) => r.code.toLowerCase() == relCode.toLowerCase() ||
                      r.name.toLowerCase() == emergencyRelation.value.toLowerCase(),
                );
              }
            }

            final address = data['home_address']?.toString() ?? '';
            if (address.isNotEmpty) {
              final parts = address.split(',');
              if (!_isDisposed) {
                if (parts.isNotEmpty) cityCtrl.text = parts[0].trim();
              }
              if (parts.length > 1) selectedState.value = parts[1].trim();
            }

            final insurance = data['insurance'];
            if (insurance != null) {
              if (!_isDisposed) {
                insuranceProviderCtrl.text = insurance['provider']?.toString() ?? '';
                policyNumberCtrl.text = insurance['policy_number']?.toString() ?? '';
              }
              if (insuranceProviderCtrl.text.isNotEmpty || policyNumberCtrl.text.isNotEmpty) {
                showInsurance.value = true;
              }
            }
          }
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? '');
        }
      }
    } catch (e) {
      PrintLog.printLog("Exception getPatientProfileAPI: $e");
    } finally {
      if (!_isDisposed) isLoading.value = false;
    }
  }

  // ==================================================================
  // ---------------------  API : update-profile  ---------------------
  // ==================================================================
  Future<void> updateProfileAPI(BuildContext context, VoidCallback onSuccess) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> dictParameter = <String, dynamic>{
        "full_name": fullNameCtrl.text.trim(),
        "date_of_birth": selectedDob.value != null
            ? DateFormat('yyyy-MM-dd').format(selectedDob.value!)
            : '',
        "email": emailCtrl.text.trim(),
        "gender": selectedGender.value.toLowerCase(),
        "nationality": selectedNationalityId.value,
      };
      final token = await StorageService().getString(StorageService.token);

      Map<String, dynamic>? response;
      if (profileImage.value != null) {
        final formData = dio.FormData.fromMap(dictParameter);
        formData.files.add(MapEntry(
          'profile_photo',
          await dio.MultipartFile.fromFile(
            profileImage.value!.path,
            filename: 'profile.jpg',
          ),
        ));
        final raw = await ApiProvider().requestMultipartApi(
          context,
          WebApiConstant.API_URL_VERIFY_UPDATE_PROFILE,
          formData,
          token ?? '',
        );
        if (raw != null && raw.data is Map) {
          response = Map<String, dynamic>.from(raw.data as Map);
        }
      } else {
        response = await ApiProvider().updateProfileApi(
          context,
          WebApiConstant.API_URL_VERIFY_UPDATE_PROFILE,
          dictParameter,
          token!,
        );
      }

      isLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          Fluttertoast.showToast(msg: response['message'] ?? 'Profile updated successfully.');
          // Keep Profile screen name in sync after edit
          profileDisplayName.value = fullNameCtrl.text.trim();

          final data = response['data'];
          final userData = data is Map ? data['user'] : null;
          if (userData is Map) {
            final storage = StorageService();
            await storage.setString(StorageService.userName, userData['full_name']?.toString() ?? '');
            await storage.setString(StorageService.email, userData['email']?.toString() ?? '');
          }

          final photoFromRes = data is Map
              ? _normalizePhotoUrl(
                  (data['profile_photo'] ??
                          data['profile_picture'] ??
                          (userData is Map ? userData['profile_photo'] : null))
                      ?.toString(),
                )
              : '';
          if (photoFromRes.isNotEmpty) {
            profilePhotoUrl.value = photoFromRes;
            profileImage.value = null;
          }
          // Else keep local File so the avatar still shows until next fetch.

          onSuccess();
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? '');
        }
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  // ==================================================================
  // ---------------------  API : update-medical  ----------------------
  // ==================================================================
  Future<void> updateMedicalAPI(BuildContext context, VoidCallback onSuccess) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> dictParameter = <String, dynamic>{
        "blood_group": bloodGroup.value,
        "height": double.tryParse(heightCtrl.text.trim()) ?? 0,
        "weight": double.tryParse(weightCtrl.text.trim()) ?? 0,
        "marital_status": maritalStatus.value.toLowerCase(),
        "occupation": selectedOccupationModel.value?.code ?? occupationCtrl.text.trim(),
        "chronic_disease": hasChronicDisease.value,
        "physically_handicapped": isPhysicallyHandicapped.value,
        "disability_type": isPhysicallyHandicapped.value 
            ? (selectedDisabilityTypeModel.value?.code ?? disabilityTypeCtrl.text.trim()) 
            : "",
        "organ_donor": isOrganDonor.value,
        "allergies": selectedAllergies.toList(),
        "medications": selectedMedications.toList(),
      };

      final response = await ApiProvider().updateMedicalApi(
        context,
        WebApiConstant.API_URL_PATIENT_UPDATE_MEDICAL,
        dictParameter,
        userAccessToken!,
      );

      isLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          Fluttertoast.showToast(msg: response['message'] ?? 'Medical information updated successfully.');
          onSuccess();
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? '');
        }
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  // ==================================================================
  // --------------------  API : update-emergency  ---------------------
  // ==================================================================
  Future<void> updateEmergencyAPI(BuildContext context, VoidCallback onSuccess) async {
    try {
      isLoading.value = true;

      final homeAddress = [cityCtrl.text.trim(), selectedState.value]
          .where((e) => e.isNotEmpty)
          .join(', ');

      final Map<String, dynamic> dictParameter = <String, dynamic>{
        "contact_name": emergencyNameCtrl.text.trim(),
        "relation": selectedEmergencyRelationModel.value?.code ?? emergencyRelation.value.toLowerCase(),
        "mobile_number": emergencyMobileCtrl.text.trim(),
        "home_address": homeAddress,
        "insurance_provider": insuranceProviderCtrl.text.trim(),
        "policy_number": policyNumberCtrl.text.trim(),
      };

      final response = await ApiProvider().updateEmergencyAPI(
        context,
        WebApiConstant.API_URL_PATIENT_UPDATE_EMERGENCY,
        dictParameter,
        userAccessToken!,
      );

      isLoading.value = false;
      if (_isDisposed) return;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          Fluttertoast.showToast(
              msg: response['message'] ?? 'Emergency & Insurance details updated successfully.');
          onSuccess();
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? '');
        }
      }
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    fullNameCtrl.dispose();
    emailCtrl.dispose();
    dobCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    occupationCtrl.dispose();
    disabilityTypeCtrl.dispose();
    medicationInputCtrl.dispose();
    emergencyNameCtrl.dispose();
    emergencyMobileCtrl.dispose();
    cityCtrl.dispose();
    insuranceProviderCtrl.dispose();
    policyNumberCtrl.dispose();
    super.onClose();
  }
}