import 'package:get/get.dart';
import 'package:healaura/app/data/models/doctor_model.dart';
import 'package:healaura/DataProvider/api_provider.dart';
import 'package:healaura/DataProvider/web_api_constant.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../data/services/storage_service.dart';
import 'package:healaura/app/core/Util/app_toast.dart';

enum FindSortMode { nearest, rating, reviews, name }

enum FindLocationMode { nearMe, city }

class FindController extends GetxController {
  var specializations = <Specialization>[].obs;
  var hospitals = <Hospital>[].obs;
  var isLoading = false.obs;
  var isHospitalLoading = false.obs;
  /// 0 = All specialties; 1..n map to specializations[i-1]
  var selectedSpecIndex = 0.obs;
  var showMap = false.obs;
  var searchQuery = ''.obs;
  var sortMode = FindSortMode.nearest.obs;

  /// SMART FILTERS
  final selectedSpecialties = <String>{}.obs; // specialization names
  var locationMode = FindLocationMode.nearMe.obs;
  var selectedCity = ''.obs;
  /// null = any; else minimum rating floor (3 / 4 / 4.5)
  var minRating = Rxn<double>();
  /// '' | in_clinic | online
  var consultationType = ''.obs;
  /// '' | male | female | any
  var genderPreference = ''.obs;
  /// selected language label (empty = any)
  var languagePreference = ''.obs;

  static const ratingOptions = <double>[3.0, 4.0, 4.5];
  static const consultationOptions = [
    {'value': 'in_clinic', 'label': 'In-clinic'},
    {'value': 'online', 'label': 'Online'},
  ];
  static const genderOptions = [
    {'value': 'male', 'label': 'Male'},
    {'value': 'female', 'label': 'Female'},
    {'value': 'any', 'label': 'Any'},
  ];
  static const languageOptions = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Marathi',
    'Gujarati',
    'Punjabi',
  ];

  var hospitalDetail = Rxn<HospitalDetail>();
  var isDetailLoading = false.obs;
  var userPosition = Rxn<Position>();
  /// Current user already reviewed the open hospital/clinic.
  var hasUserReviewed = false.obs;

  List<String> get availableCities {
    final cities = hospitals
        .map((h) => h.cityName.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cities;
  }

  int get activeFilterCount {
    var n = 0;
    if (selectedSpecialties.isNotEmpty) n++;
    if (locationMode.value == FindLocationMode.city &&
        selectedCity.value.isNotEmpty) {
      n++;
    }
    if (minRating.value != null) n++;
    if (consultationType.value.isNotEmpty) n++;
    if (genderPreference.value.isNotEmpty &&
        genderPreference.value != 'any') {
      n++;
    }
    if (languagePreference.value.isNotEmpty) n++;
    return n;
  }

  /// Client-side filter + sort over API hospital list (does not change API).
  List<Hospital> get filteredHospitals {
    var list = List<Hospital>.from(hospitals);
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((h) {
        return h.name.toLowerCase().contains(q) ||
            h.cityName.toLowerCase().contains(q) ||
            h.address.toLowerCase().contains(q) ||
            h.hospitalType.toLowerCase().contains(q);
      }).toList();
    }

    // Multi-select specializations (or legacy single chip index).
    final specs = selectedSpecialties
        .map((e) => e.toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (specs.isEmpty &&
        selectedSpecIndex.value > 0 &&
        selectedSpecIndex.value <= specializations.length) {
      specs.add(
        specializations[selectedSpecIndex.value - 1].name.toLowerCase(),
      );
    }
    if (specs.isNotEmpty) {
      list = list.where((h) {
        final type = h.hospitalType.toLowerCase();
        final name = h.name.toLowerCase();
        final deps = h.specializationTags.map((e) => e.toLowerCase());
        return specs.any((s) =>
            type.contains(s) ||
            name.contains(s) ||
            deps.any((d) => d.contains(s)));
      }).toList();
    }

    if (locationMode.value == FindLocationMode.city &&
        selectedCity.value.trim().isNotEmpty) {
      final city = selectedCity.value.trim().toLowerCase();
      list = list
          .where((h) =>
              h.cityName.toLowerCase() == city ||
              h.cityName.toLowerCase().contains(city) ||
              h.address.toLowerCase().contains(city))
          .toList();
    }

    final floor = minRating.value;
    if (floor != null) {
      list = list
          .where((h) => (double.tryParse(h.averageRating) ?? 0) >= floor)
          .toList();
    }

    final consult = consultationType.value.trim().toLowerCase();
    if (consult.isNotEmpty) {
      list = list.where((h) {
        final tags = h.consultationTypes.map((e) => e.toLowerCase()).toList();
        if (tags.isEmpty) return true; // no data → don't force-empty list
        if (consult == 'online') {
          return tags.any((t) => t.contains('online') || t.contains('tele'));
        }
        return tags.any((t) =>
            t.contains('clinic') ||
            t.contains('in_clinic') ||
            t.contains('in-clinic') ||
            t.contains('hospital'));
      }).toList();
    }

    final gender = genderPreference.value.trim().toLowerCase();
    if (gender.isNotEmpty && gender != 'any') {
      list = list.where((h) {
        final g = (h.genderPreference ?? '').toLowerCase();
        if (g.isEmpty) return true;
        return g.contains(gender);
      }).toList();
    }

    final lang = languagePreference.value.trim().toLowerCase();
    if (lang.isNotEmpty) {
      list = list.where((h) {
        final langs = h.languages.map((e) => e.toLowerCase()).toList();
        if (langs.isEmpty) return true;
        return langs.any((l) => l.contains(lang));
      }).toList();
    }

    switch (sortMode.value) {
      case FindSortMode.rating:
        list.sort((a, b) => (double.tryParse(b.averageRating) ?? 0)
            .compareTo(double.tryParse(a.averageRating) ?? 0));
        break;
      case FindSortMode.reviews:
        list.sort((a, b) => b.totalReviews.compareTo(a.totalReviews));
        break;
      case FindSortMode.name:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case FindSortMode.nearest:
        final pos = userPosition.value;
        if (pos != null) {
          list.sort((a, b) {
            final da = _distanceKm(pos, a);
            final db = _distanceKm(pos, b);
            if (da == null && db == null) {
              if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
              return (double.tryParse(b.averageRating) ?? 0)
                  .compareTo(double.tryParse(a.averageRating) ?? 0);
            }
            if (da == null) return 1;
            if (db == null) return -1;
            return da.compareTo(db);
          });
        } else {
          list.sort((a, b) {
            if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
            return (double.tryParse(b.averageRating) ?? 0)
                .compareTo(double.tryParse(a.averageRating) ?? 0);
          });
        }
        break;
    }
    return list;
  }

  double? _distanceKm(Position pos, Hospital h) {
    final lat = double.tryParse(h.latitude ?? '');
    final lng = double.tryParse(h.longitude ?? '');
    if (lat == null || lng == null) return null;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng) /
        1000.0;
  }

  void setSearch(String value) {
    searchQuery.value = value;
  }

  void selectSpecialty(int index) {
    selectedSpecIndex.value = index;
    // Keep multi-select in sync with strip taps.
    if (index <= 0) {
      selectedSpecialties.clear();
    } else if (index <= specializations.length) {
      final name = specializations[index - 1].name;
      selectedSpecialties
        ..clear()
        ..add(name);
    }
  }

  void toggleSpecialtyFilter(String name) {
    if (selectedSpecialties.contains(name)) {
      selectedSpecialties.remove(name);
    } else {
      selectedSpecialties.add(name);
    }
    // Sync strip highlight to first selected (or All).
    if (selectedSpecialties.isEmpty) {
      selectedSpecIndex.value = 0;
    } else {
      final first = selectedSpecialties.first;
      final i = specializations.indexWhere((s) => s.name == first);
      selectedSpecIndex.value = i >= 0 ? i + 1 : 0;
    }
  }

  void setLocationMode(FindLocationMode mode) {
    locationMode.value = mode;
    if (mode == FindLocationMode.nearMe) {
      selectedCity.value = '';
    }
  }

  void setSelectedCity(String? city) {
    selectedCity.value = city?.trim() ?? '';
    if (selectedCity.value.isNotEmpty) {
      locationMode.value = FindLocationMode.city;
    }
  }

  void setMinRating(double? value) {
    minRating.value = value;
  }

  void setConsultationType(String? value) {
    consultationType.value = value?.trim() ?? '';
  }

  void setGenderPreference(String? value) {
    genderPreference.value = value?.trim() ?? '';
  }

  void setLanguagePreference(String? value) {
    languagePreference.value = value?.trim() ?? '';
  }

  void clearSmartFilters() {
    selectedSpecialties.clear();
    selectedSpecIndex.value = 0;
    locationMode.value = FindLocationMode.nearMe;
    selectedCity.value = '';
    minRating.value = null;
    consultationType.value = '';
    genderPreference.value = '';
    languagePreference.value = '';
  }

  void setSort(FindSortMode mode) {
    sortMode.value = mode;
  }

  String get sortLabel {
    switch (sortMode.value) {
      case FindSortMode.nearest:
        return 'Nearest';
      case FindSortMode.rating:
        return 'Top rated';
      case FindSortMode.reviews:
        return 'Most reviewed';
      case FindSortMode.name:
        return 'A–Z';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchSpecializations();
    // Do not pop the OS location dialog on tab load — splash gate / user tap handles that.
    fetchHospitals(requestLocation: false);
  }

  Future<void> fetchSpecializations() async {
    try {
      isLoading(true);
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().getSpecializationsAPI(null, token ?? '');
      if (response != null && response['error'] == false) {
        var rawData = response['data'];
        List data = [];
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map && rawData.containsKey('results')) {
          data = rawData['results'];
        }
        specializations.value = data.map((e) => Specialization.fromJson(e)).toList();
      }
    } finally {
      isLoading(false);
    }
  }

  /// User ki current position lene aur permissions handle karne ke liye.
  /// [requestIfNeeded] false = never show OS dialog (post-splash gate owns first ask).
  Future<Position?> _determinePosition({bool requestIfNeeded = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (requestIfNeeded) {
        Get.snackbar(
          "Location Disabled",
          "Please enable location services to find doctors near you.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          mainButton: TextButton(
            onPressed: () => Geolocator.openLocationSettings(),
            child: const Text("Enable",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestIfNeeded) return null;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          "Permission Denied",
          "Location permissions are required to find nearby doctors.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (requestIfNeeded) {
        Get.snackbar(
          "Permission Blocked",
          "Location permissions are permanently denied. Please enable them in settings.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          mainButton: TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text("Settings",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Nearby Doctors API ko fetch karne ke liye
  Future<void> fetchHospitals({bool requestLocation = false}) async {
    try {
      isHospitalLoading(true);

      // Location hasil karein
      Position? position =
          await _determinePosition(requestIfNeeded: requestLocation);
      userPosition.value = position;
      
      if (position == null) {
        isHospitalLoading(false);
        return;
      }

      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      
      // Nearby API call with lat/lng
      final response = await ApiProvider().getNearbyDoctorsAPI(
        null, 
        position.latitude, 
        position.longitude, 
        token ?? ''
      );
      print("Hospital Response:.... ${response}");

      if (response != null && response['error'] == false) {
        var rawData = response['data'];
        List data = [];
        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map && rawData.containsKey('results')) {
          data = rawData['results'];
        }
        hospitals.value = data.map((e) => Hospital.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching nearby doctors: $e");
    } finally {
      isHospitalLoading(false);
    }
  }

  Future<void> fetchHospitalDetail(String hospitalId) async {
    try {
      isDetailLoading(true);
      hasUserReviewed.value = false;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().getHospitalDetailAPI(null, hospitalId, token ?? '');
      print("Hospital Detail Response: $response");
      if (response != null && response['error'] == false) {
        final detail = HospitalDetail.fromJson(response['data']);
        hospitalDetail.value = detail;
        final local = await StorageService().hasReviewedPlace(hospitalId);
        hasUserReviewed.value = detail.hasReviewed || local;
        if (detail.hasReviewed) {
          await StorageService().markPlaceReviewed(hospitalId);
        }
      }
    } finally {
      isDetailLoading(false);
    }
  }

  bool _looksLikeAlreadyReviewed(String? message) {
    final m = (message ?? '').toLowerCase();
    return m.contains('already') ||
        m.contains('already reviewed') ||
        m.contains('duplicate') ||
        m.contains('exist') ||
        m.contains('once');
  }

  /// Returns true when review was accepted (or already on file).
  Future<bool> submitReview({
    required String id,
    required double rating,
    required String comment,
    required bool isHospital,
  }) async {
    if (hasUserReviewed.value) {
      AppToast.showToast(msg: 'You have already reviewed this place');
      return false;
    }
    try {
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      String url = isHospital
          ? "${WebApiConstant.API_URL_HOSPITAL_REVIEW}$id/review/"
          : "${WebApiConstant.API_URL_CLINIC_REVIEW}$id/review/";

      final response = await ApiProvider().postReviewAPI(
        null,
        url,
        {
          "rating": rating.toInt(),
          "comment": comment,
        },
        token ?? '',
      );

      if (response != null && response['error'] == false) {
        await StorageService().markPlaceReviewed(id);
        hasUserReviewed.value = true;
        fetchHospitalDetail(id);
        Get.snackbar("Success", "Review submitted successfully",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      }

      final msg = response?['message']?.toString() ?? 'Failed to submit review';
      if (_looksLikeAlreadyReviewed(msg)) {
        await StorageService().markPlaceReviewed(id);
        hasUserReviewed.value = true;
        AppToast.showToast(msg: 'You have already reviewed this place');
        return false;
      }
      AppToast.showToast(msg: msg);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Something went wrong",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }
}
