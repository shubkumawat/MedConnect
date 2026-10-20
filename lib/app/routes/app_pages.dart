import 'package:get/get.dart';
import '../../features/splash/view/splash_screen.dart';
import '../../features/splash/controller/splash_controller.dart';
import '../../features/onboarding/view/onboarding_screen.dart';
import '../../features/onboarding/controller/onboarding_controller.dart';
import '../../features/auth/view/mobile_login_screen.dart';
import '../../features/auth/view/otp_verification_screen.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/profile_setup/view/profile_setup_parent.dart';
import '../../features/profile_setup/controller/profile_setup_controller.dart';
import '../../features/home/view/home_dashboard_screen.dart';
import '../../features/home/controller/home_controller.dart';
import '../../features/records/view/disease_detail_screen.dart';
import '../../features/records/view/add_disease_screen.dart';
import '../../features/records/view/add_medication_screen.dart';
import '../../features/records/view/ai_prescription_reader_screen.dart';
import '../../features/records/view/health_timeline_screen.dart';
import '../../features/records/controller/records_controller.dart';
import '../../features/records/controller/ai_prescription_controller.dart';
import '../../features/qr/view/patient_qr_screen.dart';
import '../../features/qr/controller/qr_controller.dart';
import '../../features/family/view/my_patients_screen.dart';
import '../../features/family/view/add_family_member_screen.dart';
import '../../features/family/view/access_control_screen.dart';
import '../../features/family/controller/family_controller.dart';
import '../../features/find/view/find_doctor_screen.dart';
import '../../features/find/view/doctor_profile_screen.dart';
import '../../features/find/view/find_hospital_screen.dart';
import '../../features/find/view/appointment_booking_screen.dart';
import '../../features/find/controller/find_controller.dart';
import '../../features/videos/view/video_topic_browser_screen.dart';
import '../../features/videos/view/video_reel_player_screen.dart';
import '../../features/videos/controller/video_controller.dart';
import '../../features/notifications/view/notification_center_screen.dart';
import '../../features/notifications/controller/notification_controller.dart';
import '../../features/profile/view/my_profile_screen.dart';
import '../../features/profile/view/emergency_contacts_screen.dart';
import '../../features/profile/view/health_tips_screen.dart';
import '../../features/profile/view/settings_screen.dart';
import '../../features/profile/controller/profile_controller.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static List<GetPage> get routes => [
    GetPage(
      name: '/splash',
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: '/onboarding',
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder(() {
        Get.put(OnboardingController());
      }),
    ),
    GetPage(
      name: '/login',
      page: () => const MobileLoginScreen(),
    ),
    GetPage(
      name: '/otp',
      page: () => const OtpVerificationScreen(),
    ),
    GetPage(
      name: '/profile-setup',
      page: () => const ProfileSetupParent(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ProfileSetupController());
      }),
    ),
    GetPage(
      name: '/home',
      page: () => const HomeDashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => HomeController());
        Get.lazyPut(() => RecordsController());
        Get.lazyPut(() => FamilyController());
        Get.lazyPut(() => FindController());
        Get.lazyPut(() => ProfileController());
      }),
    ),
    GetPage(name: '/disease-detail', page: () => const DiseaseDetailScreen()),
    GetPage(name: '/add-disease', page: () => const AddDiseaseScreen()),
    GetPage(name: '/add-medication', page: () => const AddMedicationScreen()),
    GetPage(
      name: '/ai-reader',
      page: () => const AiPrescriptionReaderScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AiPrescriptionController());
      }),
    ),
    GetPage(name: '/timeline', page: () => const HealthTimelineScreen()),
    GetPage(
      name: '/qr-view',
      page: () => const PatientQRScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => QrController());
      }),
    ),
    GetPage(name: '/family-list', page: () => const MyPatientsScreen()),
    GetPage(name: '/add-family', page: () => const AddFamilyMemberScreen()),
    GetPage(name: '/access-control', page: () => const AccessControlScreen()),
    GetPage(
      name: '/video-topics',
      page: () => const VideoTopicBrowserScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => VideoController());
      }),
    ),
    GetPage(name: '/video-player', page: () => const VideoReelPlayerScreen()),
    GetPage(name: '/find-doctor', page: () => const FindDoctorScreen()),
    GetPage(name: '/doctor-profile', page: () => const DoctorProfileScreen()),
    GetPage(name: '/find-hospital', page: () => const FindHospitalScreen()),
    GetPage(name: '/appointment-booking', page: () => const AppointmentBookingScreen()),
    GetPage(
      name: '/notifications',
      page: () => const NotificationCenterScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => NotificationController());
      }),
    ),
    GetPage(name: '/emergency-contacts', page: () => const EmergencyContactsScreen()),
    GetPage(name: '/health-tips', page: () => const HealthTipsScreen()),
    GetPage(name: '/settings', page: () => const SettingsScreen()),
  ];
}
