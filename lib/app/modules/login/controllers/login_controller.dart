import 'dart:async';

import 'package:healaura/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import 'package:healaura/app/core/Util/Print/print_log.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../profile/views/personal_info_view.dart';

class LoginController extends GetxController {
  static const int resendCooldownSeconds = 30;
  static const int maxOtpAttempts = 5;
  static const int lockoutSeconds = 60;

  String? userAccessToken;

  RxBool showOtp = false.obs;
  RxBool isLoading = false.obs;
  RxString receivedOtp = "".obs;
  Rx<TextEditingController> phoneController = TextEditingController().obs;

  // Resend cooldown
  RxInt resendSecondsLeft = 0.obs;
  Timer? _resendTimer;

  // Invalid-OTP / lockout handling
  RxInt otpAttempts = 0.obs;
  RxInt otpRebuildKey = 0.obs; // bump to force-clear the OTP boxes
  RxInt lockoutSecondsLeft = 0.obs;
  Timer? _lockoutTimer;

  // Country logic
  RxBool isCountryLoading = false.obs;
  RxList<CountryModel> countryList = <CountryModel>[].obs;
  Rx<CountryModel?> selectedCountry = Rx<CountryModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Context is not available immediately in onInit, but we can fetch it later or
    // use a delay if needed. Usually for master data it's fine.
    // However, getSendOtpAPI takes context. Let's make getMasterCountryAPI separate.
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    _lockoutTimer?.cancel();
    super.onClose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 1) {
        resendSecondsLeft.value = 0;
        timer.cancel();
      } else {
        resendSecondsLeft.value--;
      }
    });
  }

  void _startLockout() {
    _lockoutTimer?.cancel();
    lockoutSecondsLeft.value = lockoutSeconds;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (lockoutSecondsLeft.value <= 1) {
        lockoutSecondsLeft.value = 0;
        otpAttempts.value = 0;
        timer.cancel();
      } else {
        lockoutSecondsLeft.value--;
      }
    });
  }

  Future<void> getMasterCountryAPI(BuildContext context) async {
    try {
      isCountryLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getAllMasterDataAPI(
        context,
        WebApiConstant.API_URL_MASTER_ALL,
        {},
        userAccessToken ?? '',
      );

      isCountryLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          // API structure: response['data']['countries'] is the list
          final List list = response['data']?['countries'] ?? [];
          countryList.value = list.map((e) => CountryModel.fromJson(e)).toList();

          // Set India as default if found
          if (selectedCountry.value == null && countryList.isNotEmpty) {
            selectedCountry.value = countryList.firstWhereOrNull(
              (c) => c.name.toLowerCase() == 'india' || c.phoneCode == '91'
            ) ?? countryList.first;
          }
        }
      }
    } catch (e) {
      isCountryLoading.value = false;
      PrintLog.printLog("Exception: $e");
    }
  }

  Future<void> getSendOtpAPI(BuildContext context) async {
    try {
      if (phoneController.value.text.isEmpty || phoneController.value.text.length != 10) {
        Fluttertoast.showToast(msg: "Please enter valid mobile number");
        return;
      }
      if (resendSecondsLeft.value > 0) {
        Fluttertoast.showToast(msg: "Please wait ${resendSecondsLeft.value}s before resending");
        return;
      }

      await StorageService()
          .getString(StorageService.token)
          .then((value) => userAccessToken = value);
      isLoading.value = true;

      final response = await ApiProvider().loginApi(
        context,
        WebApiConstant.API_URL_SEND_OTP,
        {
          "mobile_number": phoneController.value.text.toString(),
        },
        userAccessToken ?? "",
      );

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] == false) {
          showOtp.value = true;
          otpAttempts.value = 0;
          otpRebuildKey.value++;
          _startResendCooldown();
          // Extract OTP from data object as seen in logs
          // if (response['data'] != null && response['data']['otp'] != null) {
          //   receivedOtp.value = response['data']['otp'].toString();
          // } else if (response['otp'] != null) {
          //   receivedOtp.value = response['otp'].toString();
          // }
          PrintLog.printLog("Received OTP Set: ${receivedOtp.value}");
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? 'Error sending OTP');
        }
      }
    } catch (e) {
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    } finally {
      update();
    }
  }

  Future<void> getVerifyOtpAPI(BuildContext context, String otp) async {
    try {
      if (lockoutSecondsLeft.value > 0) {
        Fluttertoast.showToast(
          msg: "Too many incorrect attempts. Try again in ${lockoutSecondsLeft.value}s",
        );
        return;
      }
      if (otp.isEmpty || otp.length != 6) {
        Fluttertoast.showToast(msg: "Please enter valid otp");
        return;
      }

      await StorageService()
          .getString(StorageService.token)
          .then((value) => userAccessToken = value);
      isLoading.value = true;

      final response = await ApiProvider().loginApi(
        context,
        WebApiConstant.API_URL_VERIFY_OTP,
        {
          "mobile_number": phoneController.value.text.toString(),
          "otp": otp.toString(),
        },
        userAccessToken ?? "",
      );

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          _resendTimer?.cancel();
          _lockoutTimer?.cancel();
          otpAttempts.value = 0;

          final storage = StorageService();
          await storage.setBool(StorageService.isLogin, true);
          await storage.setString(StorageService.token, response['data']['access']);
          await storage.setString(StorageService.userID, response['data']['user']['user_id']);
          await storage.setString(StorageService.mobileNo, response['data']['user']['mobile_number'].toString());
          await storage.setString(StorageService.email, response['data']['user']['email'].toString());
          await storage.setString(StorageService.userName, response['data']['user']['full_name'].toString());

          // Check if name or email is missing
          String fullName = response['data']['user']['full_name']?.toString() ?? "";
          String email = response['data']['user']['email']?.toString() ?? "";

          // Save access_type
          String accessType = response['data']['user']?['access_type']?.toString() ?? 
                             response['data']?['access_type']?.toString() ?? "1";
          await storage.setString(StorageService.accessType, accessType);

          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          
          await Future.delayed(const Duration(milliseconds: 350));

          if (fullName.isEmpty || fullName == "null" || email.isEmpty || email == "null") {
            Get.offAll(() => const PersonalInfoScreen(null, isFromLogin: true), transition: Transition.rightToLeft);
          } else {
            Get.offAll(() => const DashboardScreen(), transition: Transition.fadeIn);
          }
        } else {
          receivedOtp.value = "";
          otpRebuildKey.value++;
          otpAttempts.value++;

          if (otpAttempts.value >= maxOtpAttempts) {
            _startLockout();
            Fluttertoast.showToast(
              msg: "Too many incorrect attempts. Try again in $lockoutSeconds seconds",
            );
          } else {
            final attemptsLeft = maxOtpAttempts - otpAttempts.value;
            Fluttertoast.showToast(
              msg: "${response['message'] ?? 'Incorrect OTP'} ($attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} left)",
            );
          }
        }
      }
    } catch (e) {
      PrintLog.printLog("Exception: $e");
      Fluttertoast.showToast(msg: WebApiConstant.ApiError);
    } finally {
      update();
    }
  }
}
