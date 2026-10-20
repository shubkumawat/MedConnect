import 'package:healora/app/data/services/places_service.dart';

class Specialization {
  final String specializationId;
  final String name;
  final String slug;
  final String icon;
  final String color;
  final String description;
  final bool isFeatured;
  final int doctorCount;
  final int displayOrder;

  Specialization({
    required this.specializationId,
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
    required this.description,
    required this.isFeatured,
    required this.doctorCount,
    required this.displayOrder,
  });

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      specializationId: json['specialization_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      description: json['description'] ?? '',
      isFeatured: json['is_featured'] ?? false,
      doctorCount: json['doctor_count'] ?? 0,
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

class Hospital {
  final String hospitalId;
  final String name;
  final String slug;
  final String hospitalType;
  final String? logoUrl;
  final String? bannerUrl;
  final String cityName;
  final String address;
  final String phone;
  final bool isVerified;
  final bool isFeatured;
  final String averageRating;
  final int totalReviews;
  final String? latitude;
  final String? longitude;
  /// Optional tags from API for smarter client filters.
  final List<String> specializationTags;
  final List<String> consultationTypes;
  final String? genderPreference;
  final List<String> languages;

  Hospital({
    required this.hospitalId,
    required this.name,
    required this.slug,
    required this.hospitalType,
    this.logoUrl,
    this.bannerUrl,
    required this.cityName,
    required this.address,
    required this.phone,
    required this.isVerified,
    required this.isFeatured,
    required this.averageRating,
    required this.totalReviews,
    this.latitude,
    this.longitude,
    this.specializationTags = const [],
    this.consultationTypes = const [],
    this.genderPreference,
    this.languages = const [],
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      hospitalId: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      hospitalType: json['hospital_type'] ?? '',
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      cityName: json['city_name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      averageRating: json['average_rating']?.toString() ?? '0.00',
      totalReviews: json['total_reviews'] ?? 0,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      specializationTags: _stringList(
        json['specializations'] ??
            json['specialization_tags'] ??
            json['departments'],
      ),
      consultationTypes: _stringList(
        json['consultation_types'] ??
            json['consultation_type'] ??
            json['modes'],
      ),
      genderPreference: json['gender_preference']?.toString() ??
          json['doctor_gender']?.toString(),
      languages: _stringList(json['languages'] ?? json['language']),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return const [];
      return s.split(RegExp(r'[,|/]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return (e['name'] ?? e['label'] ?? e['title'] ?? '').toString();
            }
            return e.toString();
          })
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  factory Hospital.fromPlace(Map<String, dynamic> json) {
    final loc = json['geometry'] is Map ? json['geometry']['location'] : null;
    final types = _stringList(json['types']);
    final kind = placeKind(types);
    String? photo;
    final photos = json['photos'];
    if (photos is List && photos.isNotEmpty && photos.first is Map) {
      final ref = photos.first['photo_reference']?.toString();
      if (ref != null && ref.isNotEmpty) {
        photo = PlacesPhoto.url(ref);
      }
    }
    final vicinity = (json['vicinity'] ?? json['formatted_address'] ?? '')
        .toString();
    return Hospital(
      hospitalId: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['place_id']?.toString() ?? '',
      hospitalType: kind,
      logoUrl: photo,
      bannerUrl: photo,
      cityName: _cityFromAddress(vicinity),
      address: vicinity,
      phone: (json['formatted_phone_number'] ??
              json['international_phone_number'] ??
              '')
          .toString(),
      isVerified: json['business_status']?.toString() == 'OPERATIONAL',
      isFeatured: (json['rating'] as num?) != null &&
          (json['rating'] as num) >= 4.5,
      averageRating: (json['rating'] ?? 0).toString(),
      totalReviews: (json['user_ratings_total'] as num?)?.toInt() ?? 0,
      latitude: loc is Map ? loc['lat']?.toString() : null,
      longitude: loc is Map ? loc['lng']?.toString() : null,
      specializationTags: types,
    );
  }

  static String placeKind(List<String> types) {
    final t = types.map((e) => e.toLowerCase()).toSet();
    if (t.contains('hospital')) return 'Hospital';
    if (t.contains('dentist')) return 'Dentist';
    if (t.contains('pharmacy')) return 'Pharmacy';
    if (t.contains('doctor')) return 'Doctor';
    if (t.contains('physiotherapist') || t.contains('health')) return 'Clinic';
    return 'Health';
  }

  static String _cityFromAddress(String address) {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 1];
    return parts.isEmpty ? '' : parts.first;
  }
}

/// Photo URL builder kept here so list cards can load Google Place photos.
class PlacesPhoto {
  static String url(String photoReference, {int maxWidth = 800}) {
    return PlacesService.photoUrl(photoReference, maxWidth: maxWidth);
  }
}

class HospitalDetail extends Hospital {
  final String about;
  final String emergencyPhone;
  final String email;
  final String? website;
  final List<Facility> facilities;
  final List<Department> departments;
  /// True when the logged-in user already reviewed this place (API flag).
  final bool hasReviewed;
  final String? googleMapsUrl;
  final PlaceOpeningHours? openingHours;

  HospitalDetail({
    required super.hospitalId,
    required super.name,
    required super.slug,
    required super.hospitalType,
    super.logoUrl,
    super.bannerUrl,
    required super.cityName,
    required super.address,
    required super.phone,
    required super.isVerified,
    required super.isFeatured,
    required super.averageRating,
    required super.totalReviews,
    super.latitude,
    super.longitude,
    required this.about,
    required this.emergencyPhone,
    required this.email,
    this.website,
    required this.facilities,
    required this.departments,
    this.hasReviewed = false,
    this.googleMapsUrl,
    this.openingHours,
  });

  factory HospitalDetail.fromJson(Map<String, dynamic> json) {
    final reviewedFlag = json['has_reviewed'] ??
        json['user_has_reviewed'] ??
        json['is_reviewed'] ??
        json['already_reviewed'] ??
        false;
    final myReview = json['my_review'] ?? json['user_review'];
    final hasMyReview = myReview is Map && myReview.isNotEmpty;
    return HospitalDetail(
      hospitalId: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      hospitalType: json['hospital_type'] ?? '',
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      cityName: json['city_name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      averageRating: json['average_rating']?.toString() ?? '0.00',
      totalReviews: json['total_reviews'] ?? 0,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      about: json['about'] ?? '',
      emergencyPhone: json['emergency_phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'],
      facilities: (json['facilities'] as List?)?.map((e) => Facility.fromJson(e)).toList() ?? [],
      departments: (json['departments'] as List?)?.map((e) => Department.fromJson(e)).toList() ?? [],
      hasReviewed: reviewedFlag == true || hasMyReview,
    );
  }

  factory HospitalDetail.fromPlaceDetails(Map<String, dynamic> json) {
    final base = Hospital.fromPlace(json);
    final openingHours = PlaceOpeningHours.fromPlaces(json['opening_hours']);
    final facilities = <Facility>[];

    final reviews = json['reviews'];
    final departments = <Department>[];
    if (reviews is List) {
      for (var i = 0; i < reviews.length; i++) {
        final r = reviews[i];
        if (r is! Map) continue;
        final author = (r['author_name'] ?? 'Google review').toString();
        final rating = r['rating']?.toString() ?? '';
        final text = (r['text'] ?? '').toString();
        departments.add(
          Department(
            name: rating.isEmpty ? author : '$author · $rating★',
            description: text,
            displayOrder: i,
            isActive: true,
          ),
        );
      }
    }

    final editorial = json['editorial_summary'];
    String about = '';
    if (editorial is Map) {
      about = (editorial['overview'] ?? '').toString();
    }
    if (about.isEmpty && departments.isNotEmpty) {
      about = departments.first.description;
    }

    final phone = (json['formatted_phone_number'] ??
            json['international_phone_number'] ??
            base.phone)
        .toString();
    final mapsUrl = json['url']?.toString();
    final site = json['website']?.toString();

    return HospitalDetail(
      hospitalId: base.hospitalId,
      name: base.name,
      slug: base.slug,
      hospitalType: base.hospitalType,
      logoUrl: base.logoUrl,
      bannerUrl: base.bannerUrl,
      cityName: base.cityName,
      address: (json['formatted_address'] ?? base.address).toString(),
      phone: phone,
      isVerified: base.isVerified,
      isFeatured: base.isFeatured,
      averageRating: base.averageRating,
      totalReviews: base.totalReviews,
      latitude: base.latitude,
      longitude: base.longitude,
      about: about,
      emergencyPhone: phone,
      email: '',
      website: (site != null && site.isNotEmpty) ? site : mapsUrl,
      facilities: facilities,
      departments: departments,
      hasReviewed: false,
      googleMapsUrl: mapsUrl,
      openingHours: openingHours,
    );
  }
}

class PlaceDayHours {
  final String day;
  final String hours;

  PlaceDayHours({required this.day, required this.hours});

  bool get isClosed {
    final h = hours.toLowerCase();
    return h == 'closed' || h.contains('closed');
  }

  String get displayHours =>
      isClosed ? 'Closed' : hours.replaceAll(', ', '\n');
}

class PlaceOpeningHours {
  final bool? openNow;
  final List<PlaceDayHours> days;

  PlaceOpeningHours({this.openNow, required this.days});

  bool get hasSchedule => days.isNotEmpty || openNow != null;

  PlaceDayHours? get today {
    if (days.isEmpty) return null;
    const names = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final name = names[DateTime.now().weekday - 1];
    for (final d in days) {
      if (d.day.toLowerCase().startsWith(name)) return d;
    }
    if (days.length == 7) return days[DateTime.now().weekday - 1];
    return null;
  }

  static PlaceOpeningHours? fromPlaces(dynamic hours) {
    if (hours is! Map) return null;
    final openNow = hours['open_now'] is bool ? hours['open_now'] as bool : null;
    final days = <PlaceDayHours>[];
    final weekday = hours['weekday_text'];
    if (weekday is List) {
      for (final line in weekday) {
        final s = line.toString().trim();
        if (s.isEmpty) continue;
        final idx = s.indexOf(':');
        if (idx > 0 && idx <= 15) {
          days.add(
            PlaceDayHours(
              day: s.substring(0, idx).trim(),
              hours: s.substring(idx + 1).trim(),
            ),
          );
        } else {
          days.add(PlaceDayHours(day: '', hours: s));
        }
      }
    }
    if (days.isEmpty && openNow == null) return null;
    return PlaceOpeningHours(openNow: openNow, days: days);
  }
}

class Facility {
  final String facilityId;
  final String name;
  final String? icon;
  final String category;

  Facility({
    required this.facilityId,
    required this.name,
    this.icon,
    required this.category,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      facilityId: json['facility_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'],
      category: json['category'] ?? '',
    );
  }
}

class Department {
  final String name;
  final String description;
  final int displayOrder;
  final bool isActive;

  Department({
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.isActive,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }
}
