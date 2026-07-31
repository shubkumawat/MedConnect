import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_theme.dart';

class OtpInputRow extends StatefulWidget {
  final Function(String) onCompleted;
  final String? otp;
  const OtpInputRow({super.key, required this.onCompleted, this.otp});

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
    if (widget.otp != null && widget.otp!.isNotEmpty) {
      _fillOtp(widget.otp!);
    }
  }

  @override
  void didUpdateWidget(covariant OtpInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.otp != oldWidget.otp && widget.otp != null && widget.otp!.isNotEmpty) {
      _fillOtp(widget.otp!);
    }
  }

  void _fillOtp(String otp) {
    for (int i = 0; i < 6; i++) {
      if (i < otp.length) {
        _controllers[i].text = otp[i];
      } else {
        _controllers[i].clear();
      }
    }
    if (otp.length == 6) {
      widget.onCompleted(otp);
    }
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
              maxLength: 1,
              style: AppTextStyles.heading2.copyWith(color: AppColors.textDark, fontSize: 20),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.textFieldColor.withOpacity(0.5),
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
              onChanged: (val) {
                if (val.isNotEmpty && i < 5) {
                  _focusNodes[i + 1].requestFocus();
                }
                final otp = _controllers.map((c) => c.text).join();
                if (otp.length == 6) widget.onCompleted(otp);
              },
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }
}
