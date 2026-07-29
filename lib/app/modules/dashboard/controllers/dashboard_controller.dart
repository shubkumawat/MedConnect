import 'package:get/get.dart';
import '../../find/controllers/find_controller.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;
  final loadedIndices = <int>{0}.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
    if (!loadedIndices.contains(index)) {
      loadedIndices.add(index);
    }
  }
}
