import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'app/core/theme/app_colors.dart';
import 'app/core/theme/app_text_theme.dart';
import 'app/modules/splash/views/splash_view.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MedConnectApp());
}

class MedConnectApp extends StatelessWidget {
  const MedConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Med Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgNavy,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.teal,
          secondary: AppColors.orange,
          surface: AppColors.bgCardNavy,
        ),
        fontFamily: AppTextStyles.fontFamily,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgNavy,
          elevation: 0,
          titleTextStyle: AppTextStyles.appBar,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: AppColors.accentTeal,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.teal,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
