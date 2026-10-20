import 'dart:async';
import 'package:get/get.dart';

class QrController extends GetxController {
  var remainingSeconds = 600.obs; // 10 minutes
  var isExpired = false.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void startTimer() {
    isExpired.value = false;
    remainingSeconds.value = 600;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        isExpired.value = true;
        _timer?.cancel();
      }
    });
  }

  void regenerate() {
    startTimer();
  }

  String get timeString {
    int minutes = remainingSeconds.value ~/ 60;
    int seconds = remainingSeconds.value % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isWarning => remainingSeconds.value <= 120 && remainingSeconds.value > 60;
  bool get isCritical => remainingSeconds.value <= 60;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
