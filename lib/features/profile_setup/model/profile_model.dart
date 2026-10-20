class ProfileModel {
  String? fullName;
  DateTime? dob;
  String? gender;
  String? nationality;
  String? bloodGroup;
  double? weight;
  double? height;
  bool weightUnitKg; // true for kg, false for lbs
  bool heightUnitCm; // true for cm, false for ft
  List<String> allergies;
  bool hasChronicDisease;
  bool isOrganDonor;
  
  // Step 3
  String? emergencyContactName;
  String? emergencyContactRelation;
  String? emergencyContactMobile;
  String? homeCity;
  String? homeState;
  String? insuranceInfo;

  ProfileModel({
    this.fullName,
    this.dob,
    this.gender,
    this.nationality = 'India',
    this.bloodGroup,
    this.weight,
    this.height,
    this.weightUnitKg = true,
    this.heightUnitCm = true,
    List<String>? allergies,
    this.hasChronicDisease = false,
    this.isOrganDonor = false,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactMobile,
    this.homeCity,
    this.homeState,
    this.insuranceInfo,
  }) : this.allergies = allergies ?? [];

  int? get age {
    if (dob == null) return null;
    final today = DateTime.now();
    int age = today.year - dob!.year;
    if (today.month < dob!.month || (today.month == dob!.month && today.day < dob!.day)) {
      age--;
    }
    return age;
  }
  
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'dob': dob?.toIso8601String(),
    'gender': gender,
    'nationality': nationality,
    'bloodGroup': bloodGroup,
    'weight': weight,
    'height': height,
    'weightUnitKg': weightUnitKg,
    'heightUnitCm': heightUnitCm,
    'allergies': allergies,
    'hasChronicDisease': hasChronicDisease,
    'isOrganDonor': isOrganDonor,
    'emergencyContactName': emergencyContactName,
    'emergencyContactRelation': emergencyContactRelation,
    'emergencyContactMobile': emergencyContactMobile,
    'homeCity': homeCity,
    'homeState': homeState,
    'insuranceInfo': insuranceInfo,
  };
}
