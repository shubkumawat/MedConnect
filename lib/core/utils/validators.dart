class Validators {
  static String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return "Mobile number is required";
    }
    if (value.length != 10) {
      return "Enter exactly 10 digits";
    }
    return null;
  }





  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return "OTP is required";
    }
    if (value.length != 6) {
      return "Enter 6 digits";
    }
    return null;
  }
}
