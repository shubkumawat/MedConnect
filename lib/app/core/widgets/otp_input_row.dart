import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// Six visual OTP boxes backed by **one** TextField.
///
/// Xiaomi / Redmi (MIUI) often breaks six separate fields: SMS autofill dumps
/// the full code into the first box, and number-pad keystrokes never land.
/// A single `AutofillHints.oneTimeCode` field is what Android Autofill and
/// Google SMS consent expect.
class OtpInputRow extends StatefulWidget {
  /// Called when all 6 digits are filled (optional — does not auto-submit).
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? otp;

  const OtpInputRow({
    super.key,
    this.onCompleted,
    this.onChanged,
    this.otp,
  });

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  String _lastEmitted = '';

  @override
  void initState() {
    super.initState();
    final initial = _digitsOnly(widget.otp ?? '', max: 6);
    _ctrl = TextEditingController(text: initial);
    _focus = FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    _lastEmitted = initial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant OtpInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otp != oldWidget.otp) {
      final next = _digitsOnly(widget.otp ?? '', max: 6);
      if (next != _ctrl.text) {
        _ctrl.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
        _emit(next);
      }
    }
  }

  String _digitsOnly(String raw, {required int max}) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= max) return digits;
    return digits.substring(0, max);
  }

  void _onChanged(String value) {
    final digits = _digitsOnly(value, max: 6);
    if (digits != value) {
      _ctrl.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    if (mounted) setState(() {});
    _emit(digits);
  }

  void _emit(String otp) {
    if (otp == _lastEmitted) return;
    _lastEmitted = otp;
    widget.onChanged?.call(otp);
    if (otp.length == 6) {
      widget.onCompleted?.call(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _ctrl.text;
    final focused = _focus.hasFocus;

    return AutofillGroup(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _focus.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.show');
        },
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Row(
                  children: List.generate(6, (i) {
                    final filled = i < code.length;
                    final isCurrent = focused &&
                        ((code.isEmpty && i == 0) ||
                            (code.length < 6 && i == code.length) ||
                            (code.length == 6 && i == 5));
                    return Expanded(
                      child: Container(
                        height: 56,
                        margin: EdgeInsets.only(right: i == 5 ? 0 : 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              AppColors.textFieldColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.8,
                          ),
                        ),
                        child: Text(
                          filled ? code[i] : '',
                          style: const TextStyle(
                            inherit: false,
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: Color(0xFF111111),
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // On top so Redmi/MIUI keyboards and SMS autofill attach here.
              TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: true,
                // `number` drops keystrokes on some MIUI / Redmi keyboards.
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableSuggestions: false,
                autocorrect: false,
                obscureText: false,
                showCursor: false,
                enableInteractiveSelection: true,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  inherit: false,
                  fontFamily: 'Roboto',
                  fontSize: 1,
                  color: Colors.transparent,
                  textBaseline: TextBaseline.alphabetic,
                ),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                  counterText: '',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }
}
