import 'menstrual_cycle_model.dart';

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
    final rawList = json['family_members'] ??
        json['members'] ??
        json['results'] ??
        json['patients'];
    if (rawList is List) {
      familyMembers = <FamilyMember>[];
      for (final v in rawList) {
        if (v is Map) {
          familyMembers!.add(FamilyMember.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
    familyMemberCount = json['family_member_count'];
    final patientRaw = json['patient'] ?? json['member'];
    if (patientRaw is Map) {
      patient = FamilyMember.fromJson(Map<String, dynamic>.from(patientRaw));
    }
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
  String? abhaNumber;
  Medical? medical;
  EmergencyContact? emergencyContact;
  Insurance? insurance;
  String? homeAddress;
  Occupation? occupation;
  String? maritalStatus;
  Vitals? vitals;
  bool? fullAccess;
  bool? emergencyOnly;
  /// Whether this member has been granted access (API may send access_given).
  bool? accessGiven;
  bool? hasLogin;
  ParentPermission? parentPermission;

  /// API `access_type`: 0 = none, 1+ / 2 = access given.
  int? accessType;

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
    this.abhaNumber,
    this.medical,
    this.emergencyContact,
    this.insurance,
    this.homeAddress,
    this.occupation,
    this.maritalStatus,
    this.vitals,
    this.fullAccess,
    this.emergencyOnly,
    this.accessGiven,
    this.hasLogin,
    this.parentPermission,
    this.accessType,
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

  FamilyMember.fromJson(Map<String, dynamic> source) {
    isSelf = false;
    final json = _withNestedPatient(source);
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
    bloodGroup = json['blood_group'] is Map
        ? json['blood_group']['name']?.toString()
        : json['blood_group']?.toString();
    if (bloodGroup != null) {
      final bg = bloodGroup!.trim();
      final lower = bg.toLowerCase();
      if (bg.isEmpty ||
          lower == 'null' ||
          bg == '-' ||
          bg == '—' ||
          bg == '--') {
        bloodGroup = null;
      } else if (lower == 'unknown' ||
          lower == "don't know" ||
          lower == 'dont know') {
        bloodGroup = 'Unknown';
      } else {
        bloodGroup = bg;
      }
    }
    height = json['height']?.toString();
    weight = json['weight']?.toString();
    nationality = json['nationality'] != null
        ? (json['nationality'] is Map ? Nationality.fromJson(json['nationality']) : null)
        : null;
    email = json['email'];
    mobileNumber = json['mobile_number']?.toString() ??
        json['mobile']?.toString() ??
        json['phone']?.toString();
    abhaNumber = json['abha_number']?.toString() ??
        json['health_id']?.toString() ??
        json['abha_id']?.toString();
    if (abhaNumber != null) {
      final a = abhaNumber!.trim();
      abhaNumber = (a.isEmpty || a.toLowerCase() == 'null') ? null : a;
    }
    medical = json['medical'] != null ? Medical.fromJson(json['medical']) : null;
    emergencyContact = json['emergency_contact'] != null
        ? EmergencyContact.fromJson(json['emergency_contact'])
        : null;
    insurance = json['insurance'] != null ? Insurance.fromJson(json['insurance']) : null;
    // API may return Map {address, city, post_code, state} or a plain string.
    if (json['home_address'] is Map) {
      final m = Map<String, dynamic>.from(json['home_address'] as Map);
      homeAddress = [
        m['address'],
        m['city'],
        m['state'],
        m['post_code'] ?? m['pincode'],
      ]
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .map((e) => e.toString().trim())
          .join(', ');
    } else {
      final raw = json['home_address']?.toString();
      homeAddress = (raw == null || raw.isEmpty || raw == 'null') ? null : raw;
    }
    occupation = json['occupation'] != null
        ? (json['occupation'] is Map
            ? Occupation.fromJson(json['occupation'])
            : Occupation(name: json['occupation'].toString()))
        : null;
    maritalStatus = json['marital_status'] is Map ? json['marital_status']['name']?.toString() : json['marital_status']?.toString();
    vitals = json['vitals'] != null ? Vitals.fromJson(json['vitals']) : null;
    _applyAccessFlags(json);
  }

  static Map<String, dynamic> _withNestedPatient(Map<String, dynamic> raw) {
    final json = Map<String, dynamic>.from(raw);
    for (final key in ['patient', 'member', 'profile']) {
      final nested = raw[key];
      if (nested is Map) {
        nested.forEach((k, v) {
          json.putIfAbsent(k.toString(), () => v);
        });
      }
    }
    return json;
  }

  void _applyAccessFlags(Map<String, dynamic> json) {
    Map<String, dynamic>? box;
    for (final key in [
      'access',
      'access_control',
      'permissions',
      'record_access',
      'access_info',
    ]) {
      final v = json[key];
      if (v is Map) {
        box = Map<String, dynamic>.from(v);
        break;
      }
    }

    dynamic pick(List<String> keys) {
      for (final k in keys) {
        if (json[k] != null) return json[k];
        if (box != null && box[k] != null) return box[k];
      }
      return null;
    }

    fullAccess = _asBool(pick([
      'full_access',
      'has_full_access',
      'is_full_access',
      'full',
    ]));
    emergencyOnly = _asBool(pick([
      'emergency_only',
      'has_emergency_only',
      'is_emergency_only',
      'emergency',
    ]));
    accessGiven = _asBool(pick([
      'access_given',
      'has_access',
      'is_access_given',
      'given',
      'is_given',
      'can_access',
      'shared',
      'is_shared',
      'records_access',
    ]));

    final typeRaw = pick(['access_type', 'access_status', 'access_mode']);
    if (typeRaw is num) {
      accessType = typeRaw.toInt();
    } else if (typeRaw != null) {
      accessType = int.tryParse(typeRaw.toString().trim());
    }

    var type = typeRaw?.toString().trim().toLowerCase() ?? '';
    if (type.isEmpty && json['access'] is String) {
      type = json['access'].toString().trim().toLowerCase();
    }
    if (type.isEmpty && json['type'] is String) {
      final t = json['type'].toString().trim().toLowerCase();
      if (t == 'give' ||
          t == 'revoke' ||
          t == 'full' ||
          t == 'full_access' ||
          t == 'emergency' ||
          t == 'emergency_only') {
        type = t;
      }
    }
    if (type.contains('full')) {
      fullAccess = true;
    } else if (type.contains('emergency')) {
      emergencyOnly = true;
    } else if (type == 'give' ||
        type == 'given' ||
        type == 'granted' ||
        type == 'yes' ||
        type == 'shared') {
      accessGiven = true;
    } else if (type == 'revoke' || type == 'revoked' || type == 'none') {
      accessGiven = false;
      accessType = 0;
    }

    // API sends numeric access_type (e.g. 2 = access given, 0 = none).
    if (accessType != null && accessType! > 0) {
      accessGiven = true;
    } else if (accessType == 0) {
      accessGiven ??= false;
    }

    hasLogin = _asBool(pick([
      'has_login',
      'login_given',
      'has_account',
      'can_login',
      'login_access',
    ]));
    parentPermission = ParentPermission.tryParse(json['parent_permission']);
    if (parentPermission?.isGranted == true) {
      accessGiven = true;
    }
    if (fullAccess == true || emergencyOnly == true) {
      accessGiven = true;
    }
  }

  static bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' ||
        s == '1' ||
        s == 'yes' ||
        s == 'given' ||
        s == 'granted' ||
        s == 'full' ||
        s == 'give') {
      return true;
    }
    if (s == 'false' ||
        s == '0' ||
        s == 'no' ||
        s == 'none' ||
        s == 'revoke' ||
        s == 'revoked') {
      return false;
    }
    return null;
  }

  /// True when any share/access flag is on.
  bool get hasAccess =>
      accessGiven == true ||
      fullAccess == true ||
      emergencyOnly == true ||
      (accessType != null && accessType! > 0) ||
      parentPermission?.isGranted == true;

  /// Short label for chips / cards.
  String get accessLabel => hasAccess ? 'Access given' : 'No access';

  bool get isAdult => (age ?? 0) >= 18;

  bool get isFemale {
    final g = (gender ?? '').trim().toLowerCase();
    return g == 'female' || g == 'f' || g == 'woman';
  }

  bool get needsLoginAccess => false;

  bool get isWaitingForPermission => false;

  bool get isPermissionDeclined => false;

  /// Access is given via Give Access for any member — no waiting lock.
  bool get recordsLocked => false;

  String get parentPermissionLabel => '';

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
    data['abha_number'] = abhaNumber;
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
    data['access_given'] = accessGiven;
    data['access_type'] = accessType;
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
  List<String>? riskFactors;
  List<String>? riskFactorLabels;
  bool? chronicDisease;
  bool? physicallyHandicapped;
  String? disabilityType;
  bool? organDonor;
  String? medicalNotes;

  Medical({
    this.allergies,
    this.currentMedications,
    this.riskFactors,
    this.riskFactorLabels,
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
    if (json['risk_factors'] is List) {
      final parsed = <String>[];
      final labels = <String>[];
      for (final e in json['risk_factors'] as List) {
        if (e is Map) {
          final v = (e['value'] ?? e['code'] ?? '').toString();
          final l = (e['label'] ?? e['name'] ?? v).toString();
          if (v.isNotEmpty) {
            parsed.add(v);
            labels.add(l.isEmpty ? v : l);
          }
        } else {
          final v = e.toString();
          if (v.isNotEmpty) {
            parsed.add(v);
            labels.add(v);
          }
        }
      }
      riskFactors = parsed;
      riskFactorLabels = labels;
    }
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
    data['risk_factors'] = riskFactors;
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
