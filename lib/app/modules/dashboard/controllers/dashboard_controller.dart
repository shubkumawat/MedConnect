import 'package:get/get.dart';
import '../../find/controllers/find_controller.dart';
import '../../records/controllers/records_controller.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  final loadedIndices = <int>{0}.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
    if (!loadedIndices.contains(index)) {
      loadedIndices.add(index);
    }
    // Records tab: always load selected member's data (patient_id).
    if (index == 1 && Get.isRegistered<RecordsController>()) {
      final records = Get.find<RecordsController>();
      records.syncSelectedPatientFromHome().then((_) {
        records.refreshForSelectedPatient();
      });
    }
  }
}
