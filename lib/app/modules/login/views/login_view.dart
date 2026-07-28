import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/otp_input_row.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomTextField/CustomTextField.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = Get.put(LoginController());

  void _verifyOtp(String otp) async {
    if (mounted) {
      controller.getVerifyOtpAPI(context, otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: AppColors.accentTeal, size: 38),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  controller.showOtp.value ? 'Verify OTP' : 'Enter Mobile\nNumber',
                  style: AppTextStyles.heading1,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.showOtp.value
                      ? 'OTP sent to +91 987XX 3210'
                      : 'No password needed — your phone is your identity.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 40),
                if (!controller.showOtp.value) ...[
                  CustomTextField(
                    hint: 'Enter 10-digit mobile number',
                    controller: controller.phoneController.value,
                    prefixIcon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                  ),
                  const SizedBox(height: 24),
                  CustomPrimaryButton(
                    text: 'Send OTP',
                    isLoading: controller.isLoading.value,
                    color: AppColors.primary,
                    onTap: () => controller.getSendOtpAPI(context),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.caption,
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
                  ),
                ] else ...[
                  KeyedSubtree(
                    key: const ValueKey('otp_section'),
                    child: OtpInputRow(
                      onCompleted: _verifyOtp,
                      otp: controller.receivedOtp.value,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => controller.getSendOtpAPI(context),
                      child: const Text(
                        'Didn\'t receive OTP? Resend',
                        style: AppTextStyles.orangeLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomPrimaryButton(
                    text: 'Verify & Proceed',
                    isLoading: controller.isLoading.value,
                    color: AppColors.buttonColor,
                    onTap: () => _verifyOtp(controller.receivedOtp.value),
                  ),
                ],
                const SizedBox(height: 350),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
