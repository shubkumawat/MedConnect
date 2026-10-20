import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import '../../find/controllers/find_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../records/controllers/records_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import 'package:healora/app/core/Util/app_toast.dart';
import '../../../data/services/notification_navigation.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  final loadedIndices = <int>{0}.obs;
  bool _profileBootstrapped = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigation.flushAfterReady();
      _loadProfileOnFirstOpen();
    });
  }

  /// Profile API on first dashboard open so Home can show today/tomorrow visits.
  Future<void> _loadProfileOnFirstOpen() async {
    if (_profileBootstrapped) return;
    final ctx = Get.context;
    if (ctx == null) return;
    _profileBootstrapped = true;
    try {
      final profile = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>()
          : Get.put(ProfileController());
      await profile.getPatientProfileAPI(ctx);
    } catch (_) {
      _profileBootstrapped = false;
    }
  }

  void changeIndex(int index) {
    currentIndex.value = index;
    if (!loadedIndices.contains(index)) {
      loadedIndices.add(index);
    }
    // Records tab: always load the currently selected passport member.
    if (index == 1 && Get.isRegistered<RecordsController>()) {
      final records = Get.find<RecordsController>();
      records.syncSelectedPatientFromHome().then((_) async {
        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          var p = home.selectedPatient;
          if (p != null && p.recordsLocked) {
            AppToast.showToast(
              msg: p.needsLoginAccess
                  ? '${p.fullName ?? 'This member'} is 18 or older. Give them login access so they can grant you permission.'
                  : 'Waiting for permission to open this adult’s health records.',
            );
            p = home.patients.firstWhereOrNull((m) => m.isSelf) ??
                home.patients.firstWhereOrNull((m) => !m.recordsLocked);
            if (p != null) {
              records.applySelectedMember(p);
            }
          } else if (p != null) {
            records.applySelectedMember(p);
          }
        }
        await records.refreshForSelectedPatient();
      });
    }
  }
}
