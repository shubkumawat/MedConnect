import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/GetCountryApiResponseModel.dart';
import 'package:healora/app/core/Util/Print/print_log.dart';
import 'package:healora/app/core/Util/TextValidator/text_validation.dart';
import 'package:healora/app/core/Util/social_auth_config.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../profile/views/personal_info_view.dart';
import 'package:healora/app/core/Util/app_toast.dart';

class LoginController extends GetxController {
  static const int resendCooldownSeconds = 60;
  static const int maxOtpAttempts = 3;
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: SocialAuthConfig.googleWebClientId.trim().isEmpty
        ? null
        : SocialAuthConfig.googleWebClientId.trim(),
  );

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
        final List list = CountryModel.namedList(response['data'], 'countries');

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

      final fcmToken = (await NotificationService.instance.currentToken()).trim();
      final body = <String, dynamic>{
        "mobile_number": phoneController.text.toString(),
        "otp": otp.toString(),
      };
      // Backend requires fcmToken whenever platForm is sent.
      if (fcmToken.isNotEmpty) {
        body["fcmToken"] = fcmToken;
        body["platForm"] = Platform.isIOS ? "ios" : "android";
      }

      final response = await ApiProvider().loginApi(
        context,
        WebApiConstant.API_URL_VERIFY_OTP,
        body,
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
          await _completeLogin(response['data']);
        } else {
          final apiMsg = (response['message'] ?? '').toString();
          final tokenRequired = apiMsg.toLowerCase().contains('fcmtoken');

          // Field/validation errors are not a wrong OTP — do not burn attempts.
          if (tokenRequired) {
            AppToast.showToast(
              msg: 'Could not verify right now. Please try again.',
            );
            return;
          }

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
              msg: "${apiMsg.isEmpty ? 'Incorrect OTP' : apiMsg} ($attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} left)",
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

  Future<void> signInWithGoogle(BuildContext context) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final account = await _googleSignIn.signIn();
      if (account == null) {
        isLoading.value = false;
        return;
      }
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        isLoading.value = false;
        AppToast.showToast(
          msg:
              'Google sign-in needs a Web client ID and SHA-1 in Firebase Console.',
        );
        return;
      }

      try {
        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      } catch (e) {
        PrintLog.printLog('Firebase Google credential: $e');
      }

      final firebaseToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      await _socialLoginToBackend(
        context,
        url: WebApiConstant.API_URL_GOOGLE_LOGIN,
        provider: 'google',
        idToken: firebaseToken ?? idToken,
        accessToken: accessToken,
        email: account.email,
        fullName: account.displayName ?? '',
        photoUrl: account.photoUrl ?? '',
      );
    } on PlatformException catch (e) {
      isLoading.value = false;
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_cancelled') {
        return;
      }
      PrintLog.printLog('Google sign-in: $e');
      AppToast.showToast(msg: _googleSignInError(e));
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog('Google sign-in: $e');
      AppToast.showToast(msg: 'Google sign-in failed. Try again.');
    }
  }

  String _googleSignInError(PlatformException e) {
    final blob = '${e.code} ${e.message} ${e.details}'.toLowerCase();
    if (blob.contains('7:') || blob.contains('network')) {
      return 'No internet. Check your connection and try again.';
    }
    if (blob.contains('12500') || blob.contains('12501')) {
      return 'Google sign-in was cancelled.';
    }
    return 'Could not sign in with Google. Please use your mobile number.';
  }

  Future<void> signInWithFacebook(BuildContext context) async {
    if (isLoading.value) return;
    if (!SocialAuthConfig.isFacebookConfigured) {
      AppToast.showToast(
        msg: 'Could not sign in with Facebook. Please use your mobile number.',
      );
      return;
    }
    try {
      isLoading.value = true;
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (result.status == LoginStatus.cancelled) {
        isLoading.value = false;
        return;
      }
      if (result.status != LoginStatus.success ||
          result.accessToken == null) {
        isLoading.value = false;
        AppToast.showToast(
          msg: result.message?.toString().isNotEmpty == true
              ? result.message!
              : 'Facebook sign-in failed. Try again.',
        );
        return;
      }

      final fbToken = result.accessToken!.tokenString;
      Map<String, dynamic> profile = {};
      try {
        profile = await FacebookAuth.instance.getUserData(
          fields: 'name,email,picture',
        );
      } catch (_) {}

      try {
        final credential = FacebookAuthProvider.credential(fbToken);
        await FirebaseAuth.instance.signInWithCredential(credential);
      } catch (e) {
        PrintLog.printLog('Firebase Facebook credential: $e');
      }

      final firebaseToken =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      final picture = profile['picture'];
      final photo = picture is Map
          ? (picture['data'] is Map ? picture['data']['url'] : null)
          : null;

      await _socialLoginToBackend(
        context,
        url: WebApiConstant.API_URL_FACEBOOK_LOGIN,
        provider: 'facebook',
        idToken: firebaseToken,
        accessToken: fbToken,
        email: profile['email']?.toString() ?? '',
        fullName: profile['name']?.toString() ?? '',
        photoUrl: photo?.toString() ?? '',
      );
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog('Facebook sign-in: $e');
      AppToast.showToast(msg: 'Facebook sign-in failed. Try again.');
    }
  }

  Future<void> _socialLoginToBackend(
    BuildContext context, {
    required String url,
    required String provider,
    String? idToken,
    String? accessToken,
    required String email,
    required String fullName,
    required String photoUrl,
  }) async {
    try {
      final fcmToken =
          (await NotificationService.instance.currentToken()).trim();
      final body = <String, dynamic>{
        'provider': provider,
        'email': email,
        'full_name': fullName,
        'photo_url': photoUrl,
      };
      if (idToken != null && idToken.isNotEmpty) {
        body['id_token'] = idToken;
        body['idToken'] = idToken;
      }
      if (accessToken != null && accessToken.isNotEmpty) {
        body['access_token'] = accessToken;
        body['accessToken'] = accessToken;
        body['token'] = accessToken;
      }
      if (fcmToken.isNotEmpty) {
        body['fcmToken'] = fcmToken;
        body['platForm'] = Platform.isIOS ? 'ios' : 'android';
      }

      final response = await ApiProvider().loginApi(
        context,
        url,
        body,
        userAccessToken ?? '',
      );
      isLoading.value = false;
      PrintLog.printLog(response);

      if (response != null &&
          response['error'] != true &&
          response['error_code'] == 0) {
        await _completeLogin(response['data']);
        return;
      }
      AppToast.showToast(
        msg: (response?['message'] ??
                'Google login is not on the server yet. Please use your mobile number.')
            .toString(),
      );
    } catch (e) {
      isLoading.value = false;
      PrintLog.printLog('Social backend: $e');
      AppToast.showToast(msg: WebApiConstant.ApiError);
    }
  }

  Future<void> _completeLogin(dynamic rawData) async {
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : <String, dynamic>{};
    final access = (data['access'] ?? data['token'] ?? '').toString();
    if (access.isEmpty) {
      AppToast.showToast(msg: 'Login succeeded but no session was returned.');
      return;
    }

    final storage = StorageService();
    await storage.setString(StorageService.token, access);
    await storage.setString(
      StorageService.userID,
      (user['user_id'] ?? data['user_id'] ?? '').toString(),
    );
    await storage.setString(
      StorageService.mobileNo,
      (user['mobile_number'] ?? '').toString(),
    );
    await storage.setString(
      StorageService.email,
      (user['email'] ?? '').toString(),
    );
    await storage.setString(
      StorageService.userName,
      (user['full_name'] ?? '').toString(),
    );
    final accessType =
        (user['access_type'] ?? data['access_type'] ?? '').toString();
    await storage.setString(StorageService.accessType, accessType);

    final dynamic newUserRaw = data['is_new_user'];
    final bool isNewUser = newUserRaw == true ||
        newUserRaw == 1 ||
        newUserRaw?.toString().toLowerCase() == 'true';

    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    await Future.delayed(const Duration(milliseconds: 350));

    if (isNewUser) {
      await storage.setBool(StorageService.profileSetupDone, false);
      Get.to(
        () => const PersonalInfoScreen(null, isFromLogin: true),
        transition: Transition.rightToLeft,
      );
    } else {
      await storage.setBool(StorageService.isLogin, true);
      await storage.setBool(StorageService.profileSetupDone, true);
      Get.offAll(() => const DashboardScreen(), transition: Transition.fadeIn);
    }
  }
}
