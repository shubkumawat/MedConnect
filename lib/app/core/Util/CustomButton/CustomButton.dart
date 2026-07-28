import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../Colors/colors.dart';
import '../Font/font_family.dart';

// ─── Primary Button (Teal/Green gradient) ───────────────────────────────────
class CustomPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final Color? color;
  final double? width;
  final double height;
  final IconData? icon;

  const CustomPrimaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.color,
    this.width,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.teal;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          // color: bg,
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.tealDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
              ],
              Text(text, style: AppTextStyles.button,),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Secondary Outline Button ────────────────────────────────────────────────
class CustomOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;
  final double? width;
  final double height;

  const CustomOutlineButton({
    super.key,
    required this.text,
    required this.onTap,
    this.borderColor = AppColors.teal,
    this.textColor = AppColors.textTeal,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.button.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

// ─── Icon Button (circular) ──────────────────────────────────────────────────
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? iconColor;
  final double size;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.bgColor,
    this.iconColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.textWhite, size: 20),
      ),
    );
  }
}

// ─── FAB (floating add button) ───────────────────────────────────────────────
class CustomFab extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;

  const CustomFab({super.key, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color ?? AppColors.teal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}