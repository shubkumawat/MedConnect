import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:healora/DataProvider/api_provider.dart';
import 'package:healora/DataProvider/app_shared_preferences.dart';
import 'package:healora/DataProvider/web_api_constant.dart';
import 'package:healora/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healora/app/core/theme/app_colors.dart';
import 'package:healora/app/core/theme/app_text_theme.dart';
import 'package:healora/app/core/widgets/live_text_field.dart';
import 'package:healora/app/data/models/bmi_result_model.dart';
import 'package:healora/app/data/models/family_member_model.dart';
import 'package:healora/app/modules/home/controllers/home_controller.dart';
import 'package:healora/app/modules/profile/controllers/profile_controller.dart';
import 'bmi_result_screen.dart';
import 'package:healora/app/core/Util/app_toast.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  /// Empty until the user picks Male / Female — no defaults.
  String _gender = '';
  bool _loading = false;
  bool _fromProfile = false;
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    FamilyMember? member;
    if (Get.isRegistered<HomeController>()) {
      member = Get.find<HomeController>().selectedPatient;
    }

    var gender = _normalizeGender(member?.gender);
    var age = member?.age;
    var height = _asCm(member?.height);
    var weight = _asKg(member?.weight);

    if (Get.isRegistered<ProfileController>()) {
      final pc = Get.find<ProfileController>();
      final useProfile =
          member == null || member.isSelf == true || member.patientId == pc.profilePatientId.value;
      if (useProfile) {
        if (gender.isEmpty) gender = _normalizeGender(pc.selectedGender.value);
        if (age == null || age == 0) {
          final a = pc.age.value;
          if (a > 0) age = a;
        }
        if (height.isEmpty) height = _asCm(pc.heightCtrl.text);
        if (weight.isEmpty) weight = _asKg(pc.weightCtrl.text);
      }
    }

    _gender = gender;
    if (age != null && age > 0) _ageCtrl.text = '$age';
    if (height.isNotEmpty) _heightCtrl.text = height;
    if (weight.isNotEmpty) _weightCtrl.text = weight;
    _fromProfile = _gender.isNotEmpty ||
        _ageCtrl.text.isNotEmpty ||
        _heightCtrl.text.isNotEmpty ||
        _weightCtrl.text.isNotEmpty;
    _profileName = member?.fullName?.trim() ?? '';
  }

  static String _normalizeGender(String? raw) {
    final g = (raw ?? '').trim().toLowerCase();
    if (g == 'male' || g == 'm' || g == 'man') return 'male';
    if (g == 'female' || g == 'f' || g == 'woman') return 'female';
    return '';
  }

  static String _asCm(String? raw) {
    final t = (raw ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
    final v = double.tryParse(t);
    if (v == null || v <= 0) return '';
    final cm = v <= 3 ? v * 100 : v;
    if (cm < 50 || cm > 250) return '';
    return cm == cm.roundToDouble() ? cm.round().toString() : cm.toStringAsFixed(1);
  }

  static String _asKg(String? raw) {
    final t = (raw ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
    final v = double.tryParse(t);
    if (v == null || v < 10 || v > 400) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final age = int.tryParse(_ageCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());

    if (_gender != 'male' && _gender != 'female') {
      AppToast.showToast(msg: 'Select gender');
      return;
    }
    if (age == null || age <= 0 || age > 120) {
      AppToast.showToast(msg: 'Enter a valid age');
      return;
    }
    if (height == null || height < 50 || height > 250) {
      AppToast.showToast(msg: 'Enter height in cm (50–250)');
      return;
    }
    if (weight == null || weight < 10 || weight > 400) {
      AppToast.showToast(msg: 'Enter a valid weight in kg');
      return;
    }

    setState(() => _loading = true);

    // Local fallback — used when API fails / empty / incomplete.
    final fallback = BmiResult.calculate(
      age: age,
      gender: _gender,
      heightCm: height,
      weightKg: weight,
    );
    var result = fallback;

    try {
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final body = <String, dynamic>{
        'age': age,
        'gender': _gender,
        'height': height,
        'weight': weight,
      };
      if (Get.isRegistered<HomeController>()) {
        final pid = Get.find<HomeController>().selectedPatientId;
        if (pid != null && pid.isNotEmpty) body['patient_id'] = pid;
      }

      final response = await ApiProvider().requestPostForApi(
        context,
        '${WebApiConstant.BASE_URL}health-records/bmi/calculate/',
        body,
        token,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        final raw = Map<String, dynamic>.from(response.data as Map);
        if (raw['error'] != true) {
          Map<String, dynamic>? data;
          if (raw['data'] is Map) {
            data = Map<String, dynamic>.from(raw['data'] as Map);
          } else if (raw['bmi'] != null || raw['bmi_value'] != null) {
            // Some APIs put fields at root.
            data = raw;
          }
          if (data != null) {
            final merged = BmiResult.mergeApiWithFallback(
              apiData: data,
              fallback: fallback,
            );
            if (merged.bmi > 0) result = merged;
          }
        }
      }
    } catch (_) {
      // Keep local fallback as-is.
      result = fallback;
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (!mounted) return;
    Get.to(() => BmiResultScreen(result: result));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'BMI Calculator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fromProfile ? 'Your saved details' : 'Enter your details',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fromProfile
                        ? (_profileName.isNotEmpty
                            ? 'Filled from $_profileName\'s profile. Change any field if needed, then calculate.'
                            : 'Filled from your profile. Change any field if needed, then calculate.')
                        : 'We’ll calculate BMI, healthy range and more.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel('Gender'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _GenderChip(
                          label: 'Male',
                          icon: Icons.male_rounded,
                          selected: _gender == 'male',
                          onTap: () => setState(() => _gender = 'male'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _GenderChip(
                          label: 'Female',
                          icon: Icons.female_rounded,
                          selected: _gender == 'female',
                          onTap: () => setState(() => _gender = 'female'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Age (years)'),
                  const SizedBox(height: 8),
                  _Input(
                    controller: _ageCtrl,
                    hint: 'e.g. 28',
                    icon: Icons.cake_outlined,
                    digitsOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Height (cm)'),
                  const SizedBox(height: 8),
                  _Input(
                    controller: _heightCtrl,
                    hint: 'e.g. 175',
                    icon: Icons.height_rounded,
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Weight (kg)'),
                  const SizedBox(height: 8),
                  _Input(
                    controller: _weightCtrl,
                    hint: 'e.g. 70',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  const SizedBox(height: 28),
                  CustomPrimaryButton(
                    text: 'Calculate',
                    icon: Icons.calculate_rounded,
                    isLoading: _loading,
                    onTap: _calculate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.captionBold.copyWith(
        color: AppColors.textGray,
        letterSpacing: 0.4,
        fontSize: 11.5,
      ),
    );
  }
}

class _Input extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool digitsOnly;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.digitsOnly = false,
  });

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final FocusNode _focus;
  bool _didSelectAll = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() {
      if (_focus.hasFocus &&
          !_didSelectAll &&
          widget.controller.text.isNotEmpty) {
        _didSelectAll = true;
        widget.controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.controller.text.length,
        );
      }
      if (!_focus.hasFocus) _didSelectAll = false;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE3EBE7)),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
    );
    return LiveTextField(
      controller: widget.controller,
      focusNode: _focus,
      keyboardType: widget.digitsOnly
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (widget.digitsOnly)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      hintText: widget.hint,
      showClearButton: true,
      prefixIcon: Icon(widget.icon, color: AppColors.tealDark, size: 22),
      filled: true,
      fillColor: Colors.white,
      border: outline,
      enabledBorder: outline,
      focusedBorder: focused,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.tealDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.tealDark : const Color(0xFFE3EBE7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.tealDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
