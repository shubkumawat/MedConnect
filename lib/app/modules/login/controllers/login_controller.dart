import 'dart:async';
import 'dart:io';

import 'package:healaura/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import 'package:healaura/app/core/Util/Print/print_log.dart';
import 'package:healaura/app/core/Util/TextValidator/text_validation.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../profile/views/personal_info_view.dart';
import 'package:healaura/app/core/Util/app_toast.dart';

class LoginController extends GetxController {
  static const int resendCooldownSeconds = 30;
  static const int maxOtpAttempts = 5;
  static const int lockoutSeconds = 60;

  String? userAccessToken;

  RxBool showOtp = false.obs;
  RxBool isLoading = false.obs;
  RxString receivedOtp = "".obs;
  /// Plain controller — never wrap TextEditingController in .obs (breaks live typing UI).
  final TextEditingController phoneController = TextEditingController();

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
    selectedCountry.value = CountryModel.indiaFallback;
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    _lockoutTimer?.cancel();
    phoneController.dispose();
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

  void _stopResendCooldown() {
    _resendTimer?.cancel();
    _resendTimer = null;
    resendSecondsLeft.value = 0;
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

      // Silent fetch — avoid CustomLoading (steals focus from phone field).
      // Use dedicated countries endpoint (same as profile / family).
      final raw = await ApiProvider().requestGetForApi(
        context,
        WebApiConstant.API_URL_MASTER_COUNTRY,
        {},
        userAccessToken ?? '',
      );

      Map<String, dynamic>? response;
      if (raw != null &&
          (raw.statusCode == 200 || raw.statusCode == 201) &&
          raw.data is Map) {
        response = Map<String, dynamic>.from(raw.data as Map);
      }

      isCountryLoading.value = false;
      PrintLog.printLog(response);

      if (response != null &&
          response['error'] != true &&
          response['error_code'] == 0) {
        // countries API returns data as a list (not data.countries).
        final dynamic data = response['data'];
        final List list = data is List
            ? data
            : (data is Map ? (data['countries'] ?? []) : []);

        countryList.value =
            list.map((e) => CountryModel.fromJson(e as Map<String, dynamic>)).toList();

        final current = selectedCountry.value;
        if (current == null || current.id == 0 || current.isIndia) {
          selectedCountry.value = CountryModel.indiaFrom(countryList);
        }
      }

      // Fallback so login always shows a code even if API fails.
      if (selectedCountry.value == null) {
        selectedCountry.value = CountryModel.indiaFallback;
      }
    } catch (e) {
      isCountryLoading.value = false;
      PrintLog.printLog("Exception: $e");
      if (selectedCountry.value == null) {
        selectedCountry.value = CountryModel.indiaFallback;
      }
    }
  }

  Future<void> getSendOtpAPI(BuildContext context) async {
    try {
      if (phoneController.text.isEmpty ||
          !TxtValidation.isValidMobile(phoneController.text)) {
        AppToast.showToast(
          msg:
              'Please enter a valid mobile number (${TxtValidation.mobileMinLength}–${TxtValidation.mobileMaxLength} digits)',
        );
        return;
      }
      if (resendSecondsLeft.value > 0) {
        AppToast.showToast(msg: "Please wait ${resendSecondsLeft.value}s before resending");
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
          "mobile_number": phoneController.text.toString(),
        },
        userAccessToken ?? "",
      );

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] == false) {
          final data = response['data'];
          final rawOtp = data is Map ? data['otp']?.toString() ?? '' : '';
          final digits = rawOtp.replaceAll(RegExp(r'[^0-9]'), '');

          showOtp.value = true;
          otpAttempts.value = 0;
          // Demo / send-otp response includes OTP — autofill boxes.
          receivedOtp.value = digits.length >= 6 ? digits.substring(0, 6) : digits;
          otpRebuildKey.value++;
          _startResendCooldown();
          PrintLog.printLog("Received OTP Set: ${receivedOtp.value}");
        } else {
          AppToast.showToast(msg: response['message'] ?? 'Error sending OTP');
        }
      }
    } catch (e) {
      PrintLog.printLog("Exception: $e");
      AppToast.showToast(msg: WebApiConstant.ApiError);
      isLoading.value = false;
    }
  }

  Future<void> getVerifyOtpAPI(BuildContext context, String otp) async {
    try {
      if (lockoutSecondsLeft.value > 0) {
        AppToast.showToast(
          msg: "Too many incorrect attempts. Try again in ${lockoutSecondsLeft.value}s",
        );
        return;
      }
      if (otp.isEmpty || otp.length != 6) {
        AppToast.showToast(msg: "Please enter valid otp");
        return;
      }

      await StorageService()
          .getString(StorageService.token)
          .then((value) => userAccessToken = value);
      isLoading.value = true;

      final fcmToken = await NotificationService.instance.currentToken();

      final response = await ApiProvider().loginApi(
        context,
        WebApiConstant.API_URL_VERIFY_OTP,
        {
          "mobile_number": phoneController.text.toString(),
          "otp": otp.toString(),
          "fcmToken": fcmToken,
          "platForm": Platform.isIOS ? "ios" : "android",
        },
        userAccessToken ?? "",
      );

      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          _stopResendCooldown();
          _lockoutTimer?.cancel();
          lockoutSecondsLeft.value = 0;
          otpAttempts.value = 0;

          final storage = StorageService();
          // await storage.setBool(StorageService.isLogin, true);
          await storage.setString(StorageService.token, response['data']['access']);
          await storage.setString(StorageService.userID, response['data']['user']['user_id']);
          await storage.setString(StorageService.mobileNo, response['data']['user']['mobile_number'].toString());
          await storage.setString(StorageService.email, response['data']['user']['email'].toString());
          await storage.setString(StorageService.userName, response['data']['user']['full_name'].toString());

          String fullName = response['data']['user']['full_name']?.toString() ?? "";
          final dynamic newUserRaw = response['data']['is_new_user'];
          final bool isNewUser = newUserRaw == true ||
              newUserRaw == 1 ||
              newUserRaw?.toString().toLowerCase() == 'true';
          PrintLog.printLog('OTP verify is_new_user=$newUserRaw fullName=$fullName');

          // Save access_type
          String accessType = response['data']['user']!['access_type']?.toString() ??
                             response['data']?['access_type']!.toString() ?? "";
          await storage.setString(StorageService.accessType, accessType);

          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          
          await Future.delayed(const Duration(milliseconds: 350));

          if (isNewUser) {
            // 3-step onboarding: Personal → Medical → Emergency
            await storage.setBool(StorageService.profileSetupDone, false);
            Get.to(
              () => const PersonalInfoScreen(null, isFromLogin: true),
              transition: Transition.rightToLeft,
            );
          }
          else {
              await storage.setBool(StorageService.isLogin, true);
              await storage.setBool(StorageService.profileSetupDone, true);
            Get.offAll(() => const DashboardScreen(), transition: Transition.fadeIn);
          }
        } else {
          receivedOtp.value = "";
          otpRebuildKey.value++;
          otpAttempts.value++;

          if (otpAttempts.value >= maxOtpAttempts) {
            _startLockout();
            AppToast.showToast(
              msg: "Too many incorrect attempts. Try again in $lockoutSeconds seconds",
            );
          } else {
            final attemptsLeft = maxOtpAttempts - otpAttempts.value;
            AppToast.showToast(
              msg: "${response['message'] ?? 'Incorrect OTP'} ($attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} left)",
            );
          }
        }
      }
    } catch (e) {
      PrintLog.printLog("Exception: $e");
      AppToast.showToast(msg: WebApiConstant.ApiError);
      isLoading.value = false;
    }
  }
}
