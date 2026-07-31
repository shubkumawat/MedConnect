import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:healaura/app/data/models/doctor_model.dart';
import 'package:healaura/DataProvider/api_provider.dart';
import 'package:healaura/DataProvider/web_api_constant.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../DataProvider/app_shared_preferences.dart';

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
    fetchHospitals();
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

  /// User ki current position lene aur permissions handle karne ke liye
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "Location Disabled",
        "Please enable location services to find doctors near you.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => Geolocator.openLocationSettings(),
          child: const Text("Enable", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
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
      Get.snackbar(
        "Permission Blocked",
        "Location permissions are permanently denied. Please enable them in settings.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () => Geolocator.openAppSettings(),
          child: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
      return null;
    } 

    return await Geolocator.getCurrentPosition();
  }

  /// Nearby Doctors API ko fetch karne ke liye
  Future<void> fetchHospitals() async {
    try {
      isHospitalLoading(true);
      
      // Location hasil karein
      Position? position = await _determinePosition();
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
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final response = await ApiProvider().getHospitalDetailAPI(null, hospitalId, token ?? '');
      print("Hospital Detail Response: $response");
      if (response != null && response['error'] == false) {

        hospitalDetail.value = HospitalDetail.fromJson(response['data']);
      }
    } finally {
      isDetailLoading(false);
    }
  }

  Future<void> submitReview({
    required String id,
    required double rating,
    required String comment,
    required bool isHospital,
  }) async {
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
        fetchHospitalDetail(id);
        Get.snackbar("Success", "Review submitted successfully",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", response?['message'] ?? "Failed to submit review",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
