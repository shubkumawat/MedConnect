import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TxtValidation {
  /// Letters, spaces, hyphen, apostrophe only — no digits.
  static final RegExp personNamePattern = RegExp(r"^[a-zA-Z]+(?:[ '\-][a-zA-Z]+)*$");

  /// Practical email: local@domain.tld
  static final RegExp emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?"
    r"(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Blocks digits while typing a person name.
  static List<TextInputFormatter> get nameFormatters => [
        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
        LengthLimitingTextInputFormatter(60),
      ];

  /// Allows typical email characters only.
  static List<TextInputFormatter> get emailFormatters => [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
        LengthLimitingTextInputFormatter(80),
      ];

  static bool isValidPersonName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return false;
    if (RegExp(r'\d').hasMatch(name)) return false;
    return personNamePattern.hasMatch(name);
  }

  static bool isValidEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return false;
    return emailPattern.hasMatch(email);
  }

  static String? personNameError(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter full name';
    if (RegExp(r'\d').hasMatch(name)) {
      return 'Name cannot contain numbers';
    }
    if (!personNamePattern.hasMatch(name)) {
      return 'Enter a valid name (letters only)';
    }
    return null;
  }

  static String? emailError(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter email';
    if (!email.contains('@')) return 'Email must include @';
    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email (e.g. name@gmail.com)';
    }
    return null;
  }

  /// Digits only, 10–15 length for mobile numbers.
  static const int mobileMinLength = 10;
  static const int mobileMaxLength = 15;

  static List<TextInputFormatter> get mobileFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(mobileMaxLength),
      ];

  static bool isValidMobile(String? value) {
    final mobile = (value ?? '').trim();
    if (mobile.length < mobileMinLength || mobile.length > mobileMaxLength) {
      return false;
    }
    return RegExp(r'^[0-9]+$').hasMatch(mobile);
  }

  static String? mobileError(String? value, {bool required = true}) {
    final mobile = (value ?? '').trim();
    if (mobile.isEmpty) {
      return required ? 'Please enter mobile number' : null;
    }
    if (!isValidMobile(mobile)) {
      return 'Mobile number must be $mobileMinLength–$mobileMaxLength digits';
    }
    return null;
  }

  static bool normalTextField(TextEditingController controller) {
    return controller.text.trim().isNotEmpty;
  }

  static bool validateMobileTextField(TextEditingController controller) {
    return isValidMobile(controller.text);
  }

  static bool validatePinTextField(TextEditingController controller) {
    return controller.text.trim().length >= 4;
  }

  static bool validatePasswordTextField(TextEditingController controller) {
    return controller.text.trim().length >= 8;
  }

  static bool otpVeTextField(TextEditingController controller) {
    return controller.text.trim().length == 6;
  }

  static bool validateEmailTextField(TextEditingController controller) {
    return isValidEmail(controller.text);
  }
}
