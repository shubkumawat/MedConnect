import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'live_text_field.dart';

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
      final digit = digits[digits.length - 1];
      _controllers[index].value = TextEditingValue(
        text: digit,
        selection: const TextSelection.collapsed(offset: 1),
      );
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      _controllers[index].clear();
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (i) {
        return Expanded(
          child: Container(
            height: 56,
            margin: EdgeInsets.only(right: i == 5 ? 0 : 8),
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            child: LiveTextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              fontSize: 22,
              keyboardType: TextInputType.number,
              textInputAction:
                  i == 5 ? TextInputAction.done : TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6), // allow paste into a box
              ],
              filled: true,
              fillColor: AppColors.textFieldColor.withValues(alpha: 0.5),
              isDense: true,
              // Horizontal pad stops digits clipping on the left edge.
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
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
