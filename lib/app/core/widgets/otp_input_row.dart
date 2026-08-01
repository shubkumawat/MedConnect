import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

class OtpInputRow extends StatefulWidget {
  final Function(String) onCompleted;
  final ValueChanged<String>? onChanged;
  final String? otp;

  const OtpInputRow({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.otp,
  });

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].onKeyEvent = (node, event) => _onKey(i, event);
    }
    if (widget.otp != null && widget.otp!.isNotEmpty) {
      _fillOtp(widget.otp!);
    }
  }

  @override
  void didUpdateWidget(covariant OtpInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otp != oldWidget.otp &&
        widget.otp != null &&
        widget.otp!.isNotEmpty) {
      _fillOtp(widget.otp!);
    }
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    // Empty box + backspace → go previous and clear that digit.
    // (Filled box backspace is handled normally by TextField/onChanged.)
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _emit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _fillOtp(String otp) {
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = i < otp.length ? otp[i] : '';
    }
    _emit();
    if (otp.length == 6) widget.onCompleted(otp);
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _emit() {
    final otp = _otp;
    widget.onChanged?.call(otp);
    if (otp.length == 6) widget.onCompleted(otp);
  }

  void _onBoxChanged(int index, String value) {
    // Paste / autofill of full code into one box.
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 1) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final focusAt = digits.length.clamp(0, 5);
      _focusNodes[focusAt].requestFocus();
      _emit();
      return;
    }

    if (digits.isNotEmpty) {
      _controllers[index].text = digits;
      _controllers[index].selection =
          const TextSelection.collapsed(offset: 1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        return Expanded(
          child: Container(
            height: 54,
            margin: EdgeInsets.only(right: i == 5 ? 0 : 8),
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction:
                  i == 5 ? TextInputAction.done : TextInputAction.next,
              style: AppTextStyles.heading2
                  .copyWith(color: AppColors.textDark, fontSize: 20),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.textFieldColor.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
              onChanged: (val) => _onBoxChanged(i, val),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
