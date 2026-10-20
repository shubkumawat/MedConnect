import 'package:get/get.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/home/controller/home_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
  }
}
