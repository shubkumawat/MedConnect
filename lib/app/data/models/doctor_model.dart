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
    );
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
