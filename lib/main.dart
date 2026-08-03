import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/core/theme/app_colors.dart';
import 'app/core/theme/app_text_theme.dart';
import 'app/modules/splash/views/splash_view.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Poppins was referenced in Theme/AppTextStyles but never bundled — missing
  // font families make TextField glyphs invisible until the field is re-tapped.
  GoogleFonts.config.allowRuntimeFetching = true;
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const HealAuraApp());
}

class HealAuraApp extends StatelessWidget {
  const HealAuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgNavy,
      colorScheme: const ColorScheme.light(
        primary: AppColors.teal,
        secondary: AppColors.orange,
        surface: AppColors.white,
        onSurface: AppColors.textDark,
        onPrimary: Colors.white,
      ),
    );
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    );

    return GetMaterialApp(
      title: 'HealAura',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textGray),
          labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
          floatingLabelStyle:
              textTheme.bodyMedium?.copyWith(color: AppColors.teal),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.teal,
          selectionColor: Color(0x402ECEC0),
          selectionHandleColor: AppColors.teal,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgNavy,
          elevation: 0,
          titleTextStyle: AppTextStyles.appBar,
          iconTheme: const IconThemeData(color: AppColors.textDark),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.tealDark,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.teal,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
