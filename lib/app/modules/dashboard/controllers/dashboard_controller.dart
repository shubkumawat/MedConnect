import 'package:get/get.dart';
import '../../find/controllers/find_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../records/controllers/records_controller.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  final loadedIndices = <int>{0}.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
    if (!loadedIndices.contains(index)) {
      loadedIndices.add(index);
    }
    // Records tab: always load the currently selected passport member.
    if (index == 1 && Get.isRegistered<RecordsController>()) {
      final records = Get.find<RecordsController>();
      records.syncSelectedPatientFromHome().then((_) async {
        // Prefer live Home selection (scroll) over any stale state.
        if (Get.isRegistered<HomeController>()) {
          final home = Get.find<HomeController>();
          final p = home.selectedPatient;
          if (p != null) {
            records.applySelectedMember(p);
          }
        }
        await records.refreshForSelectedPatient();
      });
    }
  }
}
