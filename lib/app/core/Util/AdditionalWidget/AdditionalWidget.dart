import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../Colors/colors.dart';
import '../Font/font_family.dart';


// ─── Custom App Bar ───────────────────────────────────────────────────────────
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Color? bgColor;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.bgColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.tealDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: showBack
          ? GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      )
          : leading,
      title: Text(title, style: AppTextStyles.appBar),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading3),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: AppTextStyles.tealLabel),
          ),
      ],
    );
  }
}

// ─── Divider ─────────────────────────────────────────────────────────────────
class McDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;
  const McDivider({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: AppColors.border,
    );
  }
}

// ─── Avatar with teal ring ────────────────────────────────────────────────────
class PatientAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final bool isActive;
  final double size;
  final String? label;

  const PatientAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.isActive = false,
    this.size = 50,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.accentTeal : Colors.transparent,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: color,
            radius: size / 2 - 3,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.3,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? AppColors.accentTeal : AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Pill / Filter Chip ───────────────────────────────────────────────────────
class McFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? activeColor;
  final VoidCallback onTap;

  const McFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final ac = activeColor ?? AppColors.teal;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ac : AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ac : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────
class McProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final double height;
  final String? label;

  const McProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.caption),
          const SizedBox(height: 6),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(height),
          ),
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color ?? AppColors.teal,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Setting Row ──────────────────────────────────────────────────────────────
class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? bgColor;

  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.accentTeal, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Event Row ───────────────────────────────────────────────────────
class TimelineEventRow extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isLast;

  const TimelineEventRow({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
              const SizedBox(height: 3),
              Text(time, style: AppTextStyles.caption),
              SizedBox(height: isLast ? 0 : 20),
            ],
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import '../Colors/colors.dart';
// import '../Font/font_family.dart';
// import '../StringDefine/strings.dart';
//
// Text buildText(String S, double size, String fontFamily, color) => Text(S, style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily),overflow: TextOverflow.ellipsis,);
//
// Text buildTextWithWeight({String? S, double? size, String? fontFamily, color, weight, height}) => Text(S ?? "", style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily,fontWeight: weight, height: height),overflow: TextOverflow.ellipsis,);
// Text buildTextWithWeightAlign({String? S, double? size, String? fontFamily, color, weight, height,   align}) => Text(S ?? "", style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily,fontWeight: weight, height: height),overflow: TextOverflow.clip,textAlign: align,);
//
// Text buildTextWithWeightSpace({String? S, double? size, String? fontFamily, color, weight,space}) => Text(S ?? "", style: TextStyle(fontSize: size, color: color, fontFamily: fontFamily,fontWeight: weight,letterSpacing: space),overflow: TextOverflow.clip,);
//
// Widget buildTextIntroStyle1({String? S}) => FittedBox(child: Text(S ?? "", style: TextStyle(fontSize: 35.0, color: CustomColors.blackColor, fontFamily: FontFamily.PoppinsRegular),overflow: TextOverflow.ellipsis,));
//
// Widget buildTextIntroStyle2({String? S}) => FittedBox(child: Text(S ?? "", style: TextStyle(fontSize: 35.0, color: CustomColors.darkBlueColor, fontFamily: FontFamily.PoppinsBold),overflow: TextOverflow.ellipsis,));
//
// AppBar buildAppBar({S,onTap}) => AppBar(
//
//   title:  Row(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: [
//       Expanded(child: buildTextWithWeight(S: S,size: 18.0,color: CustomColors.blackColor,weight: FontWeight.w800,fontFamily: FontFamily.PoppinsBold)),
//       // const Spacer(),
//       InkWell(onTap: onTap,child: Icon(Icons.notifications,color: CustomColors.greyColor,))
//     ],
//   ),
//   automaticallyImplyLeading: false,
//   backgroundColor: CustomColors.whiteColor,
//   elevation: 2,
// );
//
// AppBar buildAppBarWithBackBtn({S,onTap}) => AppBar(
//
//   title:  Row(
//     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//     children: [
//       InkWell(onTap: onTap,
//           child: Icon(
//             Icons.arrow_back_ios,
//             color: CustomColors.blackColor,
//             size: 19.0,
//           ),
//           // Icon(Icons.arrow_circle_left_outlined,color: CustomColors.greyColor,)
//       ),
//       const SizedBox(width: 15,),
//       Expanded(child: buildTextWithWeight(S: S,size: 18.0,color: CustomColors.blackColor,weight: FontWeight.w600,fontFamily: FontFamily.PoppinsBold)),
//     ],
//   ),
//   automaticallyImplyLeading: false,
//   backgroundColor: CustomColors.whiteColor,
//   elevation: 1,
// );
//
// AppBar buildAppBarWithLeadingActions({S,onTap}) => AppBar(
//   title: buildTextWithWeight(S: S,size: 18.0,color: CustomColors.blackColor,weight: FontWeight.w600,fontFamily: FontFamily.PoppinsBold),
//   leading: InkWell(onTap: onTap,
//     child: Icon(
//       Icons.arrow_back_ios,
//       color: CustomColors.blackColor,
//       size: 19.0,
//     ),
//     // Icon(Icons.arrow_circle_left_outlined,color: CustomColors.greyColor,)
//   ),
//   actions: [
//     Image.asset(str_logo)
//   ],
//   automaticallyImplyLeading: false,
//   backgroundColor: CustomColors.whiteColor,
//   elevation: 0,
// );