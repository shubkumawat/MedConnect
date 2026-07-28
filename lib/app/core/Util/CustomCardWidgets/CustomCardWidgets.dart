import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../Colors/colors.dart';
import '../Font/font_family.dart';


// ─── Base Card ───────────────────────────────────────────────────────────────
class McCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool isPremium;
  final String? heroTag;

  const McCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius = 16,
    this.border,
    this.onTap,
    this.isPremium = true,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: isPremium
          ? BoxDecoration(
              color: color ?? AppColors.bgCardNavy,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ??
                  Border(
                    left: BorderSide(color: AppColors.teal, width: 4),
                    top: BorderSide(color: AppColors.teal, width: 4),
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : BoxDecoration(
              color: color ?? AppColors.bgCardNavy,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: AppColors.border, width: 1),
            ),
      child: child,
    );

    if (heroTag != null) {
      card = Hero(
        tag: heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: card,
        ),
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─── Disease Card (with status badge) ────────────────────────────────────────
class DiseaseCard extends StatelessWidget {
  final String name;
  final String status;
  final String diagnosed;
  final String doctor;
  final VoidCallback? onTap;
  final String? heroTag;

  const DiseaseCard({
    super.key,
    required this.name,
    required this.status,
    required this.diagnosed,
    required this.doctor,
    this.onTap,
    this.heroTag,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.teal;
      case 'monitoring':
        return AppColors.teal;
      case 'resolved':
        return AppColors.teal;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: AppColors.teal, width: 4),
          top: BorderSide(color: _statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    'Diagnosed: $diagnosed · $doctor',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          // Status badge
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: AppTextStyles.caption.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );

    if (heroTag != null) {
      card = Hero(
        tag: heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: card,
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

// ─── Stat Card (for home dashboard) ──────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color accentColor;
  final IconData icon;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: accentColor),
          ),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Doctor Card ──────────────────────────────────────────────────────────────
class DoctorCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String hospital;
  final String rating;
  final VoidCallback? onTap;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCardNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 3),
                  Text(
                    '$specialty · $hospital',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            // Rating
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                const SizedBox(width: 3),
                Text(rating, style: AppTextStyles.captionBold),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────
class NotificationCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isHighlighted;

  const NotificationCard({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.orange.withOpacity(0.12)
            : AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.orange : AppColors.border,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: AppTextStyles.body.copyWith(color: AppColors.primary)),
          ),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ─── Family Member Card ───────────────────────────────────────────────────────
class FamilyMemberCard extends StatelessWidget {
  final String name;
  final String relation;
  final Color avatarColor;
  final bool isActive;
  final VoidCallback? onTap;

  const FamilyMemberCard({
    super.key,
    required this.name,
    required this.relation,
    required this.avatarColor,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg ,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: avatarColor, width: 4),
            top: BorderSide(color: avatarColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: avatarColor.withOpacity(0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(relation, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Active', style: AppTextStyles.tealLabel),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}