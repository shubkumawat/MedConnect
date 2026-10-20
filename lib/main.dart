import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/core/theme/app_colors.dart';
import 'app/core/theme/app_motion.dart';
import 'app/core/theme/app_text_theme.dart';
import 'app/data/services/notification_navigation.dart';
import 'app/data/services/notification_service.dart';
import 'app/modules/splash/views/splash_view.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  NotificationNavigation.bind();
  GoogleFonts.config.allowRuntimeFetching = true;
  PaintingBinding.instance.imageCache.maximumSize = 160;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const HealoraApp());
}

class HealoraApp extends StatelessWidget {
  const HealoraApp({super.key});

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
      title: 'Healora',
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: AppMotion.page,
      scrollBehavior: const HealoraScrollBehavior(),
      theme: base.copyWith(
        textTheme: textTheme,
        primaryTextTheme: textTheme,
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
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
