import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/GetCountryApiResponseModel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../core/widgets/live_text_field.dart';
import '../../../core/widgets/otp_input_row.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import '../controllers/login_controller.dart';

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

  void _verifyOtp(String otp) {
    if (!mounted) return;
    controller.receivedOtp.value = otp;
    controller.getVerifyOtpAPI(context, otp);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 44),
                  Obx(
                    () => Text(
                      controller.showOtp.value
                          ? 'Verification code'
                          : 'Welcome back',
                      style: AppTextStyles.heading1.copyWith(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => controller.showOtp.value
                        ? _buildOtpSubtitle()
                        : Text(
                            'Sign in with your mobile number to access your family\'s health records.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textGray,
                              height: 1.4,
                            ),
                          ),
                  ),
                  const SizedBox(height: 36),
                  // Keep phone / OTP in separate Obx branches so OTP timers
                  // never rebuild (and remount) the phone TextField.
                  Obx(() {
                    if (controller.showOtp.value) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildOtpStep(),
                      );
                    }
                    return const _PhoneStep();
                  }),
                  const SizedBox(height: 40),
                  _buildSecureFooter(),
                ],
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
                color: AppColors.primary.withValues(alpha: 0.06),
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
                color: AppColors.accentOrange.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -26,
            right: -18,
            child: Icon(
              Icons.medical_information_rounded,
              size: 150,
              color: AppColors.primary.withValues(alpha: 0.045),
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
    final number = controller.phoneController.text;
    return RichText(
      text: TextSpan(
        style:
            AppTextStyles.body.copyWith(color: AppColors.textGray, height: 1.4),
        children: [
          const TextSpan(text: 'Enter the 6-digit code sent to '),
          TextSpan(
            text: '$code $number',
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.textDark),
          ),
          const TextSpan(text: '  '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => controller.showOtp.value = false,
              child: Text(
                'Change',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOtpStep() {
    return [
      KeyedSubtree(
        key: ValueKey('otp_section_${controller.otpRebuildKey.value}'),
        child: OtpInputRow(
          onCompleted: _verifyOtp,
          onChanged: (otp) => controller.receivedOtp.value = otp,
        ),
      ),
      const SizedBox(height: 14),
      Obx(() {
        if (controller.lockoutSecondsLeft.value > 0) {
          return Text(
            'Too many incorrect attempts. Try again in ${controller.lockoutSecondsLeft.value}s',
            style: AppTextStyles.caption.copyWith(color: AppColors.statusRed),
          );
        }
        if (controller.otpAttempts.value > 0) {
          return Text(
            'Incorrect code · ${LoginController.maxOtpAttempts - controller.otpAttempts.value} attempt(s) left',
            style: AppTextStyles.caption.copyWith(color: AppColors.statusRed),
          );
        }
        return const SizedBox.shrink();
      }),
      const SizedBox(height: 8),
      Obx(
        () => controller.resendSecondsLeft.value > 0
            ? Text(
                'Resend code in ${controller.resendSecondsLeft.value}s',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textGray),
              )
            : GestureDetector(
                onTap: () => controller.getSendOtpAPI(context),
                child: Text(
                  "Didn't receive the code? Resend",
                  style: AppTextStyles.orangeLabel,
                ),
              ),
      ),
      const SizedBox(height: 28),
      Obx(
        () => CustomPrimaryButton(
          text: 'Verify & Proceed',
          isLoading: controller.isLoading.value,
          color: AppColors.buttonColor,
          onTap: () => _verifyOtp(controller.receivedOtp.value),
        ),
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

/// Isolated phone step so country/loading Obx updates don't remount the number field.
class _PhoneStep extends StatelessWidget {
  const _PhoneStep();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOBILE NUMBER',
          style: AppTextStyles.captionBold
              .copyWith(color: AppColors.textGray, letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.textFieldColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Row(
            children: [
              Obx(() {
                final loading = controller.isCountryLoading.value &&
                    controller.countryList.isEmpty;
                final selected = controller.selectedCountry.value;
                return InkWell(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12)),
                  onTap: loading
                      ? null
                      : () {
                          showModalBottomSheet<CountryModel>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) {
                              return McDropdownSheet(
                                title: 'Country / Code',
                                items: controller.countryList.toList(),
                                selected: selected,
                                labelOf: (c) =>
                                    '${c.flagEmoji}  ${c.name}  (+${c.phoneCode})',
                              );
                            },
                          ).then((value) {
                            if (value != null) {
                              controller.selectedCountry.value = value;
                            }
                          });
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.teal,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selected != null
                                    ? '${selected.flagEmoji} ${selected.phoneCode}'
                                    : '🌐',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 16, color: AppColors.textDark),
                            ],
                          ),
                  ),
                );
              }),
              Container(
                width: 1,
                height: 28,
                color: AppColors.teal.withValues(alpha: 0.4),
              ),
              Expanded(
                child: LiveTextField(
                  key: const ValueKey('login_mobile_field'),
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  hintText: 'Mobile number',
                  showClearButton: true,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => CustomPrimaryButton(
            text: 'Continue',
            isLoading: controller.isLoading.value,
            color: AppColors.primary,
            icon: Icons.arrow_forward_rounded,
            onTap: () => controller.getSendOtpAPI(context),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textGray, height: 1.4),
            children: [
              const TextSpan(text: 'By continuing you agree to our '),
              TextSpan(
                text: 'Terms',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' & '),
              TextSpan(
                text: 'Privacy Policy',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lightweight country picker sheet used by login phone step.
class McDropdownSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T) labelOf;

  const McDropdownSheet({
    super.key,
    required this.title,
    required this.items,
    required this.labelOf,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F6F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = item == selected;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.tealDark
                              : const Color(0xFFE3EBE7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              labelOf(item),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.tealDark, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
