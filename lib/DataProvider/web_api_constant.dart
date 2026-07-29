
class WebApiConstant {
  static const String BASE_URL = "https://medconnect.airainnovations.com/api/v1/";

  // Auth
  static const String API_URL_SEND_OTP                     = BASE_URL + "accounts/send-otp/";
  static const String API_URL_VERIFY_OTP                   = BASE_URL + "accounts/verify-otp/";
  static const String API_URL_VERIFY_UPDATE_PROFILE        = BASE_URL + "accounts/update-profile/";

  // Patient / Family
  static const String API_URL_PATIENT_PROFILE              = BASE_URL + "patients/profile/";
  static const String API_URL_PATIENT_UPDATE_MEDICAL       = BASE_URL + "patients/update-medical/";
  static const String API_URL_PATIENT_UPDATE_EMERGENCY     = BASE_URL + "patients/update-emergency/";
  static const String API_URL_ADD_FAMILY_MEMBER            = BASE_URL + "patients/add-family-member/";
  static const String API_URL_UPDATE_FAMILY_MEMBER         = BASE_URL + "patients/update-family-member/";
  static const String API_URL_DELETE_FAMILY_MEMBER         = BASE_URL + "patients/delete-family-member/";
  static const String API_URL_FAMILY_MEMBER_COUNT          = BASE_URL + "patients/family-member-count/";
  static const String API_URL_FAMILY_MEMBER_LIST           = BASE_URL + "patients/family-members/";
  static const String API_URL_FAMILY_MEMBER_DETAIL         = BASE_URL + "patients/family-member-detail/";

  // Access Management
  static const String API_URL_UPDATE_ACCESS_CONTROL        = BASE_URL + "patients/update-access-control/";

  // Master Data
  static const String API_URL_MASTER_ALL                   = BASE_URL + "master/";
  static const String API_URL_MASTER_COUNTRY               = BASE_URL + "master/countries/";
  static const String API_URL_MASTER_RELATIONS             = BASE_URL + "master/relations/";
  static const String API_URL_MASTER_OCCUPATIONS           = BASE_URL + "master/occupations/";
  static const String API_URL_MASTER_DISABILITY_TYPES     = BASE_URL + "master/disability-types/";

  // Video APIs
  static const String API_URL_VIDEO_TOPICS                 = BASE_URL + "videos/topics/";
  static const String API_URL_VIDEO_TOPICS_FEATURED        = BASE_URL + "videos/topics/featured/";
  static const String API_URL_VIDEO_TRENDING               = BASE_URL + "videos/trending/";
  static const String API_URL_VIDEO_BY_TOPIC               = BASE_URL + "videos/topics/"; // /{topic_id}/videos/
  static const String API_URL_VIDEO_BASE                   = BASE_URL + "videos/";
  static const String API_URL_VIDEO_CONTINUE_WATCHING      = BASE_URL + "videos/continue-watching/";
  static const String API_URL_VIDEO_SAVED                  = BASE_URL + "videos/saved/";
  static const String API_URL_VIDEO_HISTORY                = BASE_URL + "videos/history/";

  // Doctor / Hospital APIs
  static const String API_URL_DOCTOR_SPECIALIZATIONS      = BASE_URL + "doctor/specializations/";
  static const String API_URL_DOCTOR_NEARBY              = BASE_URL + "doctor/nearby/";
  static const String API_URL_HOSPITALS                    = BASE_URL + "doctor/hospitals/";
  static const String API_URL_HOSPITAL_DETAIL             = BASE_URL + "doctor/hospitals/"; // /{hospital_id}/
  static const String API_URL_HOSPITAL_REVIEW             = BASE_URL + "doctor/hospitals/"; // /{hospital_id}/review/
  static const String API_URL_CLINIC_REVIEW               = BASE_URL + "doctor/clinics/";   // /{clinic_id}/review/

  // Error Msgs
  static const String ApiError = "Something went wrong, Please try again later";
  static const String NameError = "Enter valid name";
  static const String EmailError = "Enter valid email";
}
