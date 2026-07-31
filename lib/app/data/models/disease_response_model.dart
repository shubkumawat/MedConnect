class DiseaseResponseModel {
  bool? error;
  int? errorCode;
  String? message;
  Data? data;

  DiseaseResponseModel({this.error, this.errorCode, this.message, this.data});

  DiseaseResponseModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    errorCode = json['error_code'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
}

class Data {
  int? count;
  int? page;
  int? pageSize;
  int? totalPages;
  bool? hasNext;
  bool? hasPrevious;
  String? next;
  String? previous;
  List<DiseaseResult>? results;

  Data(
      {this.count,
      this.page,
      this.pageSize,
      this.totalPages,
      this.hasNext,
      this.hasPrevious,
      this.next,
      this.previous,
      this.results});

  Data.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    page = json['page'];
    pageSize = json['page_size'];
    totalPages = json['total_pages'];
    hasNext = json['has_next'];
    hasPrevious = json['has_previous'];
    next = json['next'];
    previous = json['previous'];
    if (json['results'] != null) {
      results = <DiseaseResult>[];
      json['results'].forEach((v) {
        results!.add(DiseaseResult.fromJson(v));
      });
    }
  }
}

class DiseaseResult {
  String? uuid;
  String? displayId;
  bool? isArchived;
  String? createdAt;
  String? updatedAt;
  String? name;
  String? icdCode;
  String? conditionType;
  String? status;
  String? severity;
  String? diagnosedOn;
  String? recoveredOn;
  List<String>? bodyParts;
  String? hereditary;
  String? nextFollowUpOn;
  bool? hospitalizationRequired;
  String? admittedOn;
  String? dischargedOn;
  String? notes;
  String? category;
  String? aiInsights;
  int? medicationsCount;
  int? documentsCount;

  DiseaseResult(
      {this.uuid,
      this.displayId,
      this.isArchived,
      this.createdAt,
      this.updatedAt,
      this.name,
      this.icdCode,
      this.conditionType,
      this.status,
      this.severity,
      this.diagnosedOn,
      this.recoveredOn,
      this.bodyParts,
      this.hereditary,
      this.nextFollowUpOn,
      this.hospitalizationRequired,
      this.admittedOn,
      this.dischargedOn,
      this.notes,
      this.category,
      this.aiInsights,
      this.medicationsCount,
      this.documentsCount});

  DiseaseResult.fromJson(Map<String, dynamic> json) {
    uuid = json['uuid'];
    displayId = json['display_id'];
    isArchived = json['is_archived'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    name = json['name'];
    icdCode = json['icd_code'];
    conditionType = json['condition_type'];
    status = json['status'];
    severity = json['severity'];
    diagnosedOn = json['diagnosed_on'];
    recoveredOn = json['recovered_on'];
    if (json['body_parts'] != null) {
      bodyParts = List<String>.from(json['body_parts']);
    }
    hereditary = json['hereditary'];
    nextFollowUpOn = json['next_follow_up_on'];
    hospitalizationRequired = json['hospitalization_required'];
    admittedOn = json['admitted_on'];
    dischargedOn = json['discharged_on'];
    notes = json['notes'];
    category = json['category'];
    aiInsights = json['ai_insights'];
    medicationsCount = json['medications_count'];
    documentsCount = json['documents_count'];
  }
}
