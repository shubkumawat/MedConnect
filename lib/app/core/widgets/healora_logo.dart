import 'package:flutter/material.dart';

/// Full Healora wordmark (capsule + name + tagline).
class HealoraLogo extends StatelessWidget {
  static const asset = 'assets/logo/ic_logo_fulls.png';

  final double height;
  final bool chip;
  final bool elevated;

  const HealoraLogo({
    super.key,
    this.height = 40,
    this.chip = false,
    this.elevated = false,
  });

  /// White rounded chip for teal app bars — shows the full logo, not a crop.
  const HealoraLogo.chip({
    super.key,
    this.height = 32,
    this.elevated = false,
  }) : chip = true;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (!chip) return image;
    return Container(
      height: height + 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: const Color(0xFF147A68).withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: image,
    );
  }
}
