import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GradientContainer extends StatelessWidget {
  final Widget child;
  const GradientContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDeepBlue, AppColors.backgroundDark],
        ),
      ),
      child: child,
    );
  }
}
