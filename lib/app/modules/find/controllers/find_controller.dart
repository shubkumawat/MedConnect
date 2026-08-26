import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:healaura/app/data/models/doctor_model.dart';
import 'package:healaura/DataProvider/api_provider.dart';
import 'package:healaura/DataProvider/web_api_constant.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../data/services/storage_service.dart';

enum FindSortMode { nearest, rating, reviews, name }

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

  var hospitalDetail = Rxn<HospitalDetail>();
  var isDetailLoading = false.obs;
  var userPosition = Rxn<Position>();
  /// Current user already reviewed the open hospital/clinic.
  var hasUserReviewed = false.obs;

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
    if (selectedSpecIndex.value > 0 &&
        selectedSpecIndex.value <= specializations.length) {
      final spec =
          specializations[selectedSpecIndex.value - 1].name.toLowerCase();
      list = list
          .where((h) =>
              h.hospitalType.toLowerCase().contains(spec) ||
              h.name.toLowerCase().contains(spec))
          .toList();
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
        list.sort((a, b) {
          if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
          return (double.tryParse(b.averageRating) ?? 0)
              .compareTo(double.tryParse(a.averageRating) ?? 0);
        });
        break;
    }
    return list;
  }

  void setSearch(String value) {
    searchQuery.value = value;
  }

  void selectSpecialty(int index) {
    selectedSpecIndex.value = index;
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
      Fluttertoast.showToast(msg: 'You have already reviewed this place');
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
        Fluttertoast.showToast(msg: 'You have already reviewed this place');
        return false;
      }
      Fluttertoast.showToast(msg: msg);
      return false;
    } catch (e) {
      Get.snackbar("Error", "Something went wrong",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }
}
