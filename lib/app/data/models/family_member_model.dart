class FamilyMemberResponse {
  bool? error;
  int? errorCode;
  String? message;
  FamilyMemberData? data;

  FamilyMemberResponse({this.error, this.errorCode, this.message, this.data});

  FamilyMemberResponse.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    errorCode = json['error_code'];
    message = json['message'];
    data = json['data'] != null ? FamilyMemberData.fromJson(json['data']) : null;
  }
}

class FamilyMemberData {
  List<FamilyMember>? familyMembers;
  int? familyMemberCount;
  FamilyMember? patient; // For add response

  FamilyMemberData({this.familyMembers, this.familyMemberCount, this.patient});

  FamilyMemberData.fromJson(Map<String, dynamic> json) {
    if (json['family_members'] != null) {
      familyMembers = <FamilyMember>[];
      json['family_members'].forEach((v) {
        familyMembers!.add(FamilyMember.fromJson(v));
      });
    }
    familyMemberCount = json['family_member_count'];
    patient = json['patient'] != null ? FamilyMember.fromJson(json['patient']) : null;
  }
}

class FamilyMember {
  String? patientId;
  String? fullName;
  String? profilePhoto;
  String? dateOfBirth;
  int? age;
  String? gender;
  Relation? relation;
  String? bloodGroup;
  String? height;
  String? weight;
  Nationality? nationality;
  String? email;
  String? mobileNumber;
  Medical? medical;
  EmergencyContact? emergencyContact;
  Insurance? insurance;
  String? homeAddress;
  Occupation? occupation;
  String? maritalStatus;
  Vitals? vitals;
  bool? fullAccess;
  bool? emergencyOnly;

  /// True when this card is the logged-in user's own profile.
  bool isSelf = false;

  FamilyMember({
    this.patientId,
    this.fullName,
    this.profilePhoto,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.relation,
    this.bloodGroup,
    this.height,
    this.weight,
    this.nationality,
    this.email,
    this.mobileNumber,
    this.medical,
    this.emergencyContact,
    this.insurance,
    this.homeAddress,
    this.occupation,
    this.maritalStatus,
    this.vitals,
    this.fullAccess,
    this.emergencyOnly,
    this.isSelf = false,
  });

  /// Build "Me" passport card from `patients/profile/` response.
  factory FamilyMember.fromProfileJson(Map<String, dynamic> json) {
    final member = FamilyMember.fromJson(json);
    member.isSelf = true;
    member.relation = Relation(name: 'Me', code: 'self');
    member.patientId = json['patient_id']?.toString() ??
        json['id']?.toString() ??
        member.patientId;
    member.fullName = json['full_name']?.toString() ??
        json['name']?.toString() ??
        member.fullName;
    member.profilePhoto = _normalizeMediaUrl(
      json['profile_photo']?.toString() ??
          json['profile_picture']?.toString() ??
          json['photo']?.toString() ??
          member.profilePhoto,
    );
    return member;
  }

  static String? _normalizeMediaUrl(String? raw) {
    var url = (raw ?? '').trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return null;
    if (url.startsWith('//')) url = 'http:$url';
    if (url.startsWith('/')) {
      url = 'http://medconnect.airainnovations.com$url';
    }
    return url;
  }

  FamilyMember.fromJson(Map<String, dynamic> json) {
    isSelf = false;
    patientId = json['patient_id'];
    fullName = json['full_name'];
    profilePhoto = _normalizeMediaUrl(json['profile_photo']?.toString());
    dateOfBirth = json['date_of_birth'];
    age = json['age'];
    if ((age == null || age == 0) && dateOfBirth != null) {
      try {
        DateTime dob = DateTime.parse(dateOfBirth!);
        DateTime now = DateTime.now();
        int calculatedAge = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          calculatedAge--;
        }
        age = calculatedAge;
      } catch (e) {
        // Ignore parsing errors
      }
    }
    gender = json['gender'] is Map ? json['gender']['name']?.toString() : json['gender']?.toString();
    relation = json['relation'] != null
        ? (json['relation'] is Map
            ? Relation.fromJson(json['relation'])
            : Relation(name: json['relation'].toString()))
        : null;
    bloodGroup = json['blood_group'] is Map ? json['blood_group']['name']?.toString() : json['blood_group']?.toString();
    height = json['height']?.toString();
    weight = json['weight']?.toString();
    nationality = json['nationality'] != null
        ? (json['nationality'] is Map ? Nationality.fromJson(json['nationality']) : null)
        : null;
    email = json['email'];
    mobileNumber = json['mobile_number']?.toString() ??
        json['mobile']?.toString() ??
        json['phone']?.toString();
    medical = json['medical'] != null ? Medical.fromJson(json['medical']) : null;
    emergencyContact = json['emergency_contact'] != null
        ? EmergencyContact.fromJson(json['emergency_contact'])
        : null;
    insurance = json['insurance'] != null ? Insurance.fromJson(json['insurance']) : null;
    homeAddress = json['home_address'];
    occupation = json['occupation'] != null
        ? (json['occupation'] is Map
            ? Occupation.fromJson(json['occupation'])
            : Occupation(name: json['occupation'].toString()))
        : null;
    maritalStatus = json['marital_status'] is Map ? json['marital_status']['name']?.toString() : json['marital_status']?.toString();
    vitals = json['vitals'] != null ? Vitals.fromJson(json['vitals']) : null;
    fullAccess = json['full_access'];
    emergencyOnly = json['emergency_only'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['patient_id'] = patientId;
    data['full_name'] = fullName;
    data['profile_photo'] = profilePhoto;
    data['date_of_birth'] = dateOfBirth;
    data['age'] = age;
    data['gender'] = gender;
    if (relation != null) {
      data['relation'] = relation!.toJson();
    }
    data['blood_group'] = bloodGroup;
    data['height'] = height;
    data['weight'] = weight;
    if (nationality != null) {
      data['nationality'] = nationality!.toJson();
    }
    data['email'] = email;
    data['mobile_number'] = mobileNumber;
    if (medical != null) {
      data['medical'] = medical!.toJson();
    }
    if (emergencyContact != null) {
      data['emergency_contact'] = emergencyContact!.toJson();
    }
    if (insurance != null) {
      data['insurance'] = insurance!.toJson();
    }
    data['home_address'] = homeAddress;
    if (occupation != null) {
      data['occupation'] = occupation!.toJson();
    }
    data['marital_status'] = maritalStatus;
    if (vitals != null) {
      data['vitals'] = vitals!.toJson();
    }
    data['full_access'] = fullAccess;
    data['emergency_only'] = emergencyOnly;
    return data;
  }
}

class Vitals {
  String? heartRate;
  String? spo2;
  String? bloodPressure;
  String? temperature;
  String? lastUpdated;

  Vitals({this.heartRate, this.spo2, this.bloodPressure, this.temperature, this.lastUpdated});

  Vitals.fromJson(Map<String, dynamic> json) {
    heartRate = json['heart_rate']?.toString();
    spo2 = json['spo2']?.toString();
    bloodPressure = json['blood_pressure'];
    temperature = json['temperature']?.toString();
    lastUpdated = json['last_updated'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['heart_rate'] = heartRate;
    data['spo2'] = spo2;
    data['blood_pressure'] = bloodPressure;
    data['temperature'] = temperature;
    data['last_updated'] = lastUpdated;
    return data;
  }
}

class Relation {
  int? id;
  String? relationId;
  String? code;
  String? name;
  String? emoji;

  Relation({this.id, this.relationId, this.code, this.name, this.emoji});

  Relation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    relationId = json['relation_id'];
    code = json['code'];
    name = json['name'];
    emoji = json['emoji'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['relation_id'] = relationId;
    data['code'] = code;
    data['name'] = name;
    data['emoji'] = emoji;
    return data;
  }
}

class Nationality {
  int? id;
  String? name;

  Nationality({this.id, this.name});

  Nationality.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class Occupation {
  int? id;
  String? name;
  String? code;

  Occupation({this.id, this.name, this.code});

  Occupation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    return data;
  }
}

class Medical {
  List<Allergy>? allergies;
  List<String>? currentMedications;
  bool? chronicDisease;
  bool? physicallyHandicapped;
  String? disabilityType;
  bool? organDonor;
  String? medicalNotes;

  Medical({
    this.allergies,
    this.currentMedications,
    this.chronicDisease,
    this.physicallyHandicapped,
    this.disabilityType,
    this.organDonor,
    this.medicalNotes,
  });

  Medical.fromJson(Map<String, dynamic> json) {
    if (json['allergies'] != null) {
      allergies = <Allergy>[];
      json['allergies'].forEach((v) {
        allergies!.add(Allergy.fromJson(v));
      });
    }
    currentMedications = json['current_medications']?.cast<String>();
    chronicDisease = json['chronic_disease'];
    physicallyHandicapped = json['physically_handicapped'];
    disabilityType = json['disability_type'] is Map ? json['disability_type']['name']?.toString() : json['disability_type']?.toString();
    organDonor = json['organ_donor'];
    medicalNotes = json['medical_notes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (allergies != null) {
      data['allergies'] = allergies!.map((v) => v.toJson()).toList();
    }
    data['current_medications'] = currentMedications;
    data['chronic_disease'] = chronicDisease;
    data['physically_handicapped'] = physicallyHandicapped;
    data['disability_type'] = disabilityType;
    data['organ_donor'] = organDonor;
    data['medical_notes'] = medicalNotes;
    return data;
  }
}

class Allergy {
  String? allergyName;
  String? notes;

  Allergy({this.allergyName, this.notes});

  Allergy.fromJson(Map<String, dynamic> json) {
    allergyName = json['allergy_name'];
    notes = json['notes'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['allergy_name'] = allergyName;
    data['notes'] = notes;
    return data;
  }
}

class EmergencyContact {
  String? contactName;
  String? relation;
  String? phoneNumber;

  EmergencyContact({this.contactName, this.relation, this.phoneNumber});

  EmergencyContact.fromJson(Map<String, dynamic> json) {
    contactName = json['contact_name'];
    if (json['relation'] is Map) {
      relation = json['relation']['name'] ?? json['relation']['code'];
    } else {
      relation = json['relation'];
    }
    phoneNumber = json['phone_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['contact_name'] = contactName;
    data['relation'] = relation;
    data['phone_number'] = phoneNumber;
    return data;
  }
}

class Insurance {
  String? provider;
  String? policyNumber;
  String? expiryDate;

  Insurance({this.provider, this.policyNumber, this.expiryDate});

  Insurance.fromJson(Map<String, dynamic> json) {
    provider = json['provider'];
    policyNumber = json['policy_number'];
    expiryDate = json['expiry_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['provider'] = provider;
    data['policy_number'] = policyNumber;
    data['expiry_date'] = expiryDate;
    return data;
  }
}
