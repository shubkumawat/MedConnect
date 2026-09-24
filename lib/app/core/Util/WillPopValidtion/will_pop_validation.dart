import 'package:healora/app/data/services/storage_service.dart';
import 'package:healora/app/modules/login/views/login_view.dart';
import 'package:get/get.dart';
import 'package:healora/app/core/Util/app_toast.dart';

DateTime? currentBackPressTime;

Future<bool> onWillPop() {
  DateTime now = DateTime.now();
  if (currentBackPressTime == null ||
      now.difference(currentBackPressTime!) > Duration(seconds: 1)) {
    currentBackPressTime = now;
    AppToast.showToast(msg: "Are you sure want to exit app?");
    return Future.value(false);
  }
  return Future.value(true);
}

onLogout() async {
  await StorageService().clear();
  Get.back();
  Get.offAll(() => const LoginScreen());
}
