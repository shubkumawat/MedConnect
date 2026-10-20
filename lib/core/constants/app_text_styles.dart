import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle poppinsBold28 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle nunitoItalic14 = GoogleFonts.nunito(
    fontSize: 14,
    fontStyle: FontStyle.italic,
    color: AppColors.accentTeal,
  );

  static TextStyle smallWhite70 = GoogleFonts.poppins(
    fontSize: 12,
    color: AppColors.grey70,
  );

  static TextStyle poppinsBold24 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle poppinsMedium16 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static TextStyle poppinsBold18 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static TextStyle poppinsSemiBold18 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
}
