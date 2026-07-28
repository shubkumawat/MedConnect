import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import 'package:digitalhealth/app/core/Util/Print/print_log.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/views/dashboard_view.dart';

class LoginController extends GetxController {
  String? userAccessToken;

  RxBool showOtp = false.obs;
  RxBool isLoading = false.obs;
  RxString receivedOtp = "".obs;
  Rx<TextEditingController> phoneController = TextEditingController().obs;

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

  Future<void> getMasterCountryAPI(BuildContext context) async {
    try {
      isCountryLoading.value = true;
      userAccessToken = await StorageService().getString(StorageService.token);

      final response = await ApiProvider().getMasterCountryAPI(
        context,
        WebApiConstant.API_URL_MASTER_COUNTRY,
        {},
        userAccessToken ?? '',
      );

      isCountryLoading.value = false;
      PrintLog.printLog(response);

      if (response != null) {
        if (response['error'] != true && response['error_code'] == 0) {
          // API structure: response['data']['countries'] is the list
          final List list = response['data']['countries'] ?? [];
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
          // Extract OTP from data object as seen in logs
          if (response['data'] != null && response['data']['otp'] != null) {
            receivedOtp.value = response['data']['otp'].toString();
          } else if (response['otp'] != null) {
            receivedOtp.value = response['otp'].toString();
          }
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
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool(StorageService.isLogin, true);
          prefs.setString(StorageService.token, response['data']['access']);
          prefs.setString(StorageService.userID, response['data']['user']['user_id']);
          prefs.setString(StorageService.mobileNo, response['data']['user']['mobile_number'].toString());
          prefs.setString(StorageService.email, response['data']['user']['email'].toString());
          prefs.setString(StorageService.userName, response['data']['user']['full_name'].toString());

          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          
          await Future.delayed(const Duration(milliseconds: 350));
          Get.offAll(() => const DashboardScreen(), transition: Transition.fadeIn);
        } else {
          Fluttertoast.showToast(msg: response['message'] ?? '');
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
