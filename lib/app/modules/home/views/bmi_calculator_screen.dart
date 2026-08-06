import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:healaura/DataProvider/api_provider.dart';
import 'package:healaura/DataProvider/app_shared_preferences.dart';
import 'package:healaura/DataProvider/web_api_constant.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/theme/app_colors.dart';
import 'package:healaura/app/core/theme/app_text_theme.dart';
import 'package:healaura/app/core/widgets/live_text_field.dart';
import 'package:healaura/app/data/models/bmi_result_model.dart';
import 'package:healaura/app/modules/home/controllers/home_controller.dart';
import 'bmi_result_screen.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen> {
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _gender = 'male';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _prefillFromSelectedMember();
  }

  void _prefillFromSelectedMember() {
    if (!Get.isRegistered<HomeController>()) return;
    final p = Get.find<HomeController>().selectedPatient;
    if (p == null) return;
    if (p.age != null && p.age! > 0) _ageCtrl.text = '${p.age}';
    final g = (p.gender ?? '').toLowerCase();
    if (g.startsWith('f')) {
      _gender = 'female';
    } else if (g.startsWith('m')) {
      _gender = 'male';
    }
    final h = p.height?.toString().trim() ?? '';
    if (h.isNotEmpty && h.toLowerCase() != 'null') {
      _heightCtrl.text = h.replaceAll(RegExp(r'[^0-9.]'), '');
    }
    final w = p.weight?.toString().trim() ?? '';
    if (w.isNotEmpty && w.toLowerCase() != 'null') {
      _weightCtrl.text = w.replaceAll(RegExp(r'[^0-9.]'), '');
    }
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

    if (age == null || age <= 0 || age > 120) {
      Fluttertoast.showToast(msg: 'Enter a valid age');
      return;
    }
    if (height == null || height < 50 || height > 250) {
      Fluttertoast.showToast(msg: 'Enter height in cm (50–250)');
      return;
    }
    if (weight == null || weight < 10 || weight > 400) {
      Fluttertoast.showToast(msg: 'Enter a valid weight in kg');
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
                    'Enter your details',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We’ll calculate BMI, healthy range and more.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w500,
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
