import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextField that paints typed characters immediately.
///
/// Avoids the common Android issue where Theme/GoogleFonts (Poppins) makes
/// glyphs invisible / stuck on the first character until re-tap.
class LiveTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showClearButton;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final Color? fillColor;
  final bool filled;
  final EdgeInsetsGeometry? contentPadding;
  final bool isDense;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final bool autofocus;
  final double fontSize;

  const LiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.hintStyle,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = false,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.fillColor,
    this.filled = false,
    this.contentPadding,
    this.isDense = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical = TextAlignVertical.center,
    this.autofocus = false,
    this.fontSize = 16,
  });

  /// Engine/system font — never inherit Theme/GoogleFonts (Poppins).
  /// `inherit: false` requires fontSize + textBaseline (Flutter asserts both).
  static const TextStyle inputStyle = TextStyle(
    inherit: false,
    fontFamily: 'Roboto',
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: Color(0xFF111111),
    letterSpacing: 0,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );

  static const TextStyle _defaultHint = TextStyle(
    inherit: false,
    fontFamily: 'Roboto',
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: Color(0x99111111),
    letterSpacing: 0,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );

  @override
  State<LiveTextField> createState() => _LiveTextFieldState();
}

class _LiveTextFieldState extends State<LiveTextField> {
  late final TextEditingController _fallbackCtrl;
  TextEditingController get _ctrl => widget.controller ?? _fallbackCtrl;

  @override
  void initState() {
    super.initState();
    _fallbackCtrl = TextEditingController();
    _ctrl.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(covariant LiveTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _fallbackCtrl).removeListener(_onControllerTick);
      (widget.controller ?? _fallbackCtrl).addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    (widget.controller ?? _fallbackCtrl).removeListener(_onControllerTick);
    _fallbackCtrl.dispose();
    super.dispose();
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  void _clear() {
    _ctrl.clear();
    widget.onChanged?.call('');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final none = InputBorder.none;
    final hasText = _ctrl.text.isNotEmpty;
    final clearBtn = widget.showClearButton && hasText && widget.enabled
        ? IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: _clear,
            icon: const Icon(Icons.cancel_rounded,
                size: 20, color: Color(0xFF9AA8A1)),
          )
        : null;

    return TextField(
      controller: _ctrl,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: (v) {
        // Force paint so next keystrokes show immediately on Android.
        setState(() {});
        widget.onChanged?.call(v);
      },
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      autofocus: widget.autofocus,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      cursorColor: const Color(0xFF0B6E4F),
      cursorWidth: 2,
      enableSuggestions: false,
      autocorrect: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      style: LiveTextField.inputStyle.copyWith(
        fontSize: widget.fontSize,
        fontFamily: 'Roboto',
        height: 1.2,
        textBaseline: TextBaseline.alphabetic,
      ),
      // Soft strut — forceStrutHeight clips centered OTP digits on the left.
      strutStyle: StrutStyle(
        fontFamily: 'Roboto',
        fontSize: widget.fontSize,
        height: 1.2,
        forceStrutHeight: false,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ?? LiveTextField._defaultHint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon ?? clearBtn,
        filled: widget.filled,
        fillColor: widget.fillColor,
        isDense: widget.isDense,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: widget.border ?? none,
        enabledBorder: widget.enabledBorder ?? widget.border ?? none,
        focusedBorder: widget.focusedBorder ?? widget.border ?? none,
        disabledBorder: widget.border ?? none,
        errorBorder: widget.border ?? none,
        focusedErrorBorder: widget.border ?? none,
        counterText: '',
        // Avoid Material reserving icon slots that shove OTP digits left.
        prefixIconConstraints: widget.prefixIcon == null
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        suffixIconConstraints: (widget.suffixIcon == null && clearBtn == null)
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}
