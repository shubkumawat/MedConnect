import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/otp_input_row.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import '../controllers/login_controller.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = Get.put(LoginController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getMasterCountryAPI(context);
    });
  }

  void _verifyOtp(String otp) async {
    if (mounted) {
      controller.getVerifyOtpAPI(context, otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrand(),
                    const SizedBox(height: 44),
                    Text(
                      controller.showOtp.value ? 'Verification code' : 'Welcome back',
                      style: AppTextStyles.heading1.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    if (controller.showOtp.value)
                      _buildOtpSubtitle()
                    else
                      Text(
                        'Sign in with your mobile number to access your family\'s health records.',
                        style: AppTextStyles.body.copyWith(color: AppColors.textGray, height: 1.4),
                      ),
                    const SizedBox(height: 36),
                    if (!controller.showOtp.value)
                      ..._buildPhoneStep()
                    else
                      ..._buildOtpStep(),
                    const SizedBox(height: 40),
                    _buildSecureFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: -20,
            right: 40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentOrange.withOpacity(0.07),
              ),
            ),
          ),
          // Subtle medical watermark, bottom-right — decorative only.
          Positioned(
            bottom: -26,
            right: -18,
            child: Icon(
              Icons.medical_information_rounded,
              size: 150,
              color: AppColors.primary.withOpacity(0.045),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Center(
      child: Image.asset(
        'assets/logo/ic_logo_full.png',
        height: 96,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildOtpSubtitle() {
    final code = controller.selectedCountry.value?.phoneCode ?? '91';
    final number = controller.phoneController.value.text;
    return RichText(
      text: TextSpan(
        style: AppTextStyles.body.copyWith(color: AppColors.textGray, height: 1.4),
        children: [
          const TextSpan(text: 'Enter the 6-digit code sent to '),
          TextSpan(
            text: '+$code $number',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.textDark),
          ),
          const TextSpan(text: '  '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => controller.showOtp.value = false,
              child: Text(
                'Change',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneStep() {
    return [
      Text(
        'MOBILE NUMBER',
        style: AppTextStyles.captionBold.copyWith(color: AppColors.textGray, letterSpacing: 0.6),
      ),
      const SizedBox(height: 8),
      // Ek hi unified field — left me tappable country code, right me phone number
      PhoneInputWithCountry<CountryModel>(
        items: controller.countryList,
        value: controller.selectedCountry.value,
        itemLabel: (c) => "${c.flagEmoji} +${c.phoneCode}",
        countryName: (c) => c.name ?? "",   // 🔑 apne CountryModel ka sahi field name yahan daalo
        selectedItemBuilder: (c) => Text(
          "${c.flagEmoji} +${c.phoneCode}",
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        onCountryChanged: (val) {
          controller.selectedCountry.value = val;
        },
        controller: controller.phoneController.value,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 10,
        hint: 'Mobile number',
        isCountryLoading: controller.isCountryLoading.value,
      ),
      const SizedBox(height: 24),
      CustomPrimaryButton(
        text: 'Continue',
        isLoading: controller.isLoading.value,
        color: AppColors.primary,
        icon: Icons.arrow_forward_rounded,
        onTap: () => controller.getSendOtpAPI(context),
      ),
      const SizedBox(height: 20),
      RichText(
        text: TextSpan(
          style: AppTextStyles.caption.copyWith(color: AppColors.textGray, height: 1.4),
          children: [
            const TextSpan(text: 'By continuing you agree to our '),
            TextSpan(
              text: 'Terms',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy Policy',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      KeyedSubtree(
        key: ValueKey('otp_section_${controller.otpRebuildKey.value}'),
        child: OtpInputRow(
          onCompleted: _verifyOtp,
          otp: controller.receivedOtp.value,
        ),
      ),
      const SizedBox(height: 14),
      if (controller.lockoutSecondsLeft.value > 0)
        Text(
          'Too many incorrect attempts. Try again in ${controller.lockoutSecondsLeft.value}s',
          style: AppTextStyles.caption.copyWith(color: AppColors.statusRed),
        )
      else if (controller.otpAttempts.value > 0)
        Text(
          'Incorrect code · ${LoginController.maxOtpAttempts - controller.otpAttempts.value} attempt(s) left',
          style: AppTextStyles.caption.copyWith(color: AppColors.statusRed),
        ),
      const SizedBox(height: 8),
      controller.resendSecondsLeft.value > 0
          ? Text(
              'Resend code in ${controller.resendSecondsLeft.value}s',
              style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
            )
          : GestureDetector(
              onTap: () => controller.getSendOtpAPI(context),
              child: const Text(
                "Didn't receive the code? Resend",
                style: AppTextStyles.orangeLabel,
              ),
            ),
      const SizedBox(height: 28),
      CustomPrimaryButton(
        text: 'Verify & Proceed',
        isLoading: controller.isLoading.value,
        color: AppColors.buttonColor,
        onTap: () => _verifyOtp(controller.receivedOtp.value),
      ),
    ];
  }

  Widget _buildSecureFooter() {
    return Row(
      children: [
        const Icon(Icons.lock_rounded, size: 14, color: AppColors.textGray),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Your health data is encrypted and private.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
