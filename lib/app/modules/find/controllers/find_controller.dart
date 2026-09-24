import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:healora/app/core/Util/app_toast.dart';
import 'package:healora/app/data/models/doctor_model.dart';
import 'package:healora/app/data/services/places_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum FindSortMode { nearest, rating, reviews, name }

enum FindLocationMode { nearMe, city }

class FindController extends GetxController {
  var specializations = <Specialization>[].obs;
  var hospitals = <Hospital>[].obs;
  var isLoading = false.obs;
  var isHospitalLoading = false.obs;
  /// 0 = All specialties; 1..n map to specializations[i-1]
  var selectedSpecIndex = 0.obs;
  var showMap = true.obs;
  var searchQuery = ''.obs;
  /// Results stay hidden until the user submits a valid search.
  var hasSearched = false.obs;
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

  final PlacesService _places = PlacesService();

  static final _hospitalWord = RegExp(r'\bhospitals?\b', caseSensitive: false);
  static final _clinicWord = RegExp(r'\bclinics?\b', caseSensitive: false);
  static final _doctorWord = RegExp(r'\bdoctors?\b', caseSensitive: false);

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
    if (q.isNotEmpty && q.length < 2) {
      list = list.where((h) {
        return h.name.toLowerCase().contains(q) ||
            h.cityName.toLowerCase().contains(q) ||
            h.address.toLowerCase().contains(q) ||
            h.hospitalType.toLowerCase().contains(q);
      }).toList();
    }

    // Multi-select from Filters sheet only. Category chips already scope Places.
    final specs = selectedSpecialties
        .map((e) => e.toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
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
    hasSearched.value = false;
    hospitals.clear();
    showMap.value = true;
  }

  void selectSpecialty(int index) {
    selectedSpecIndex.value = index;
    if (index <= 0 || index > specializations.length) return;
    final name = specializations[index - 1].name;
    searchQuery.value = name;
    submitSearch(name);
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
    locateUser(requestIfNeeded: false);
  }

  Future<void> locateUser({bool requestIfNeeded = false}) async {
    final position = await _determinePosition(requestIfNeeded: requestIfNeeded);
    userPosition.value = position;
  }

  Future<void> fetchSpecializations() async {
    isLoading(true);
    specializations.value = [
      Specialization(
        specializationId: 'hospital',
        name: 'Hospital',
        slug: 'hospital',
        icon: '',
        color: '#0B6E4F',
        description: 'Hospitals',
        isFeatured: true,
        doctorCount: 0,
        displayOrder: 1,
      ),
      Specialization(
        specializationId: 'doctor',
        name: 'Doctor',
        slug: 'doctor',
        icon: '',
        color: '#1B9E8E',
        description: 'Doctors',
        isFeatured: true,
        doctorCount: 0,
        displayOrder: 2,
      ),
      Specialization(
        specializationId: 'clinic',
        name: 'Clinic',
        slug: 'clinic',
        icon: '',
        color: '#E67E22',
        description: 'Clinics',
        isFeatured: false,
        doctorCount: 0,
        displayOrder: 3,
      ),
    ];
    isLoading(false);
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

  static const _nearbyRadiusMeters = 20000;

  /// Re-run last nearby search, or just refresh GPS.
  Future<void> fetchHospitals({bool requestLocation = false}) async {
    if (hasSearched.value && searchQuery.value.trim().isNotEmpty) {
      await submitSearch(searchQuery.value);
      return;
    }
    await locateUser(requestIfNeeded: requestLocation);
  }

  Future<void> submitSearch(String rawQuery) async {
    final q = rawQuery.trim();
    searchQuery.value = q;
    if (q.isEmpty) {
      hasSearched.value = false;
      hospitals.clear();
      return;
    }

    try {
      isHospitalLoading(true);
      hasSearched.value = false;
      hospitals.clear();

      var pos = userPosition.value;
      if (pos == null) {
        await locateUser(requestIfNeeded: true);
        pos = userPosition.value;
      }
      if (pos == null) {
        AppToast.showToast(msg: 'Turn on location to see nearby results');
        return;
      }

      final careType = _careTypeFromQuery(q);
      final keyword = _nearbyKeyword(q);
      final pages = await Future.wait(
        _googleTypesForQuery(q).map(
          (type) => _places.nearby(
            lat: pos!.latitude,
            lng: pos.longitude,
            type: type,
            keyword: keyword,
            radiusMeters: _nearbyRadiusMeters,
          ),
        ),
      );

      final mapped = <String, Hospital>{};
      for (final item in pages.expand((e) => e)) {
        if (!_isAllowedPlace(item, careType)) continue;
        final h = Hospital.fromPlace(item);
        if (h.hospitalId.isEmpty) continue;
        mapped[h.hospitalId] = h;
      }
      hospitals.value = mapped.values.toList();
      hasSearched.value = true;
    } on PlacesException catch (e) {
      debugPrint('Places search error: $e');
      AppToast.showToast(msg: e.message);
    } catch (e) {
      debugPrint('Error searching places: $e');
      AppToast.showToast(msg: 'Could not search nearby places');
    } finally {
      isHospitalLoading(false);
    }
  }

  /// Empty keyword + type = all nearby of that type (e.g. search "hospital").
  String _nearbyKeyword(String query) {
    var k = query
        .replaceAll(_hospitalWord, ' ')
        .replaceAll(_clinicWord, ' ')
        .replaceAll(_doctorWord, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return k;
  }

  List<String> _googleTypesForQuery(String query) {
    final hospital = _hospitalWord.hasMatch(query);
    final clinic = _clinicWord.hasMatch(query);
    final doctor = _doctorWord.hasMatch(query);
    if (hospital && !clinic && !doctor) return ['hospital'];
    if ((clinic || doctor) && !hospital) return ['doctor'];
    if (hospital || clinic || doctor) {
      return [
        if (hospital) 'hospital',
        if (clinic || doctor) 'doctor',
      ];
    }
    return ['hospital', 'doctor'];
  }

  String _careTypeFromQuery(String query) {
    final hospital = _hospitalWord.hasMatch(query);
    final clinic = _clinicWord.hasMatch(query);
    final doctor = _doctorWord.hasMatch(query);
    if (hospital && !clinic && !doctor) return 'hospital';
    if (clinic && !hospital && !doctor) return 'clinic';
    if (doctor && !hospital && !clinic) return 'doctor';
    return 'any';
  }

  bool _isAllowedPlace(Map<String, dynamic> json, String careType) {
    final types = (json['types'] is List)
        ? (json['types'] as List).map((e) => e.toString().toLowerCase()).toSet()
        : <String>{};
    final name = (json['name'] ?? '').toString().toLowerCase();
    if (types.contains('pharmacy') ||
        types.contains('dentist') ||
        types.contains('restaurant') ||
        types.contains('lodging')) {
      return false;
    }
    switch (careType) {
      case 'hospital':
        return types.contains('hospital') || name.contains('hospital');
      case 'clinic':
        return types.contains('clinic') ||
            types.contains('doctor') ||
            name.contains('clinic');
      case 'doctor':
        return types.contains('doctor') || name.contains('doctor');
      default:
        return types.contains('hospital') ||
            types.contains('doctor') ||
            types.contains('clinic') ||
            name.contains('hospital') ||
            name.contains('clinic') ||
            name.contains('doctor');
    }
  }

  Future<void> fetchHospitalDetail(String hospitalId) async {
    try {
      isDetailLoading(true);
      hasUserReviewed.value = false;
      final result = await _places.details(hospitalId);
      if (result != null) {
        hospitalDetail.value = HospitalDetail.fromPlaceDetails(result);
      } else {
        AppToast.showToast(msg: 'Could not load place details');
      }
    } on PlacesException catch (e) {
      AppToast.showToast(msg: e.message);
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      AppToast.showToast(msg: 'Could not load place details');
    } finally {
      isDetailLoading(false);
    }
  }

  Future<void> openGooglePlace(HospitalDetail hospital) async {
    final url = hospital.googleMapsUrl ??
        hospital.website ??
        (hospital.latitude != null && hospital.longitude != null
            ? 'https://www.google.com/maps/search/?api=1&query=${hospital.latitude},${hospital.longitude}'
            : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(hospital.name)}');
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppToast.showToast(msg: 'Could not open Google Maps');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      AppToast.showToast(msg: 'Could not open Google Maps');
    }
  }

  /// Reviews live on Google Maps for Places results.
  Future<bool> submitReview({
    required String id,
    required double rating,
    required String comment,
    required bool isHospital,
  }) async {
    final detail = hospitalDetail.value;
    if (detail != null) {
      await openGooglePlace(detail);
    }
    return false;
  }
}

