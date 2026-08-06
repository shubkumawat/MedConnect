import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/theme/app_colors.dart';
import 'package:healaura/app/core/theme/app_text_theme.dart';
import 'package:healaura/app/data/models/bmi_result_model.dart';

class BmiResultScreen extends StatelessWidget {
  final BmiResult result;

  const BmiResultScreen({super.key, required this.result});

  Color get _categoryColor {
    switch (result.colorCategory) {
      case ColorCategory.underweight:
        return const Color(0xFFE8A317);
      case ColorCategory.normal:
        return const Color(0xFF2E9B4E);
      case ColorCategory.overweight:
        return const Color(0xFFE6B422);
      case ColorCategory.obesity:
        return const Color(0xFFD64545);
    }
  }

  String get _categoryHint {
    switch (result.colorCategory) {
      case ColorCategory.underweight:
        return 'Below the healthy range — consider a nutrition check-in.';
      case ColorCategory.normal:
        return 'You’re in a healthy BMI range. Keep it up!';
      case ColorCategory.overweight:
        return 'Slightly above healthy range — small lifestyle changes help.';
      case ColorCategory.obesity:
        return 'Above healthy range — talk to a clinician for guidance.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final bmiText = result.bmi.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                _HeaderBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Get.back(),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI Result',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Body Mass Index summary',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 20 + bottom),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE3EBE7)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tealDark.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your BMI',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: bmiText,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                  height: 1.05,
                                ),
                              ),
                              TextSpan(
                                text: ' ${result.unit}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textGray.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _categoryColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            result.category.toUpperCase(),
                            style: TextStyle(
                              color: _categoryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BmiGaugePainter(
                              bmi: result.bmi,
                              accent: _categoryColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Text(
                            (result.message != null &&
                                    result.message!.trim().isNotEmpty)
                                ? result.message!
                                : _categoryHint,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StatsCard(result: result),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.tealDark,
                            side: BorderSide(
                                color: AppColors.teal.withValues(alpha: 0.4)),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Recalculate',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.close(2),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealDark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final BmiResult result;
  const _StatsCard({required this.result});

  IconData _iconFor(String? key, String label) {
    final k = (key ?? label).toLowerCase();
    if (k.contains('weight')) return Icons.monitor_weight_outlined;
    if (k.contains('prime')) return Icons.speed_rounded;
    if (k.contains('ponderal') || k.contains('index')) {
      return Icons.straighten_rounded;
    }
    if (k.contains('range') || k.contains('bmi')) {
      return Icons.favorite_outline_rounded;
    }
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic rows from API (or local fallback rows).
    final items = result.infoRows;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.message != null && result.message!.trim().isNotEmpty) ...[
            Text(
              result.message!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.tealDark,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEAF1EE)),
            const SizedBox(height: 4),
          ],
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: Color(0xFFEAF1EE)),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(items[i].iconKey, items[i].label),
                    color: AppColors.tealDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].label,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Top semi-circle gauge (speedometer style) — left → top → right.
class _BmiGaugePainter extends CustomPainter {
  final double bmi;
  final Color accent;

  const _BmiGaugePainter({required this.bmi, required this.accent});

  static const _min = 15.0;
  static const _max = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Pivot near bottom so the arc opens upward.
    final cy = size.height * 0.92;
    final radius = math.min(size.width * 0.40, size.height * 0.82);
    const stroke = 22.0;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final segments = <({double from, double to, Color color, String? label})>[
      (from: 15, to: 18.5, color: const Color(0xFFF0C040), label: 'Under'),
      (from: 18.5, to: 25, color: const Color(0xFF2E9B4E), label: 'Normal'),
      (from: 25, to: 30, color: const Color(0xFFE8A317), label: 'Over'),
      (from: 30, to: 40, color: const Color(0xFFD64545), label: 'Obesity'),
    ];

    // Track background
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFE8EEEB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    for (final s in segments) {
      final t0 = _t(s.from);
      final t1 = _t(s.to);
      canvas.drawArc(
        rect,
        _angle(t0),
        (t1 - t0) * math.pi,
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Scale labels under the arc
    final ticks = <double>[15, 18.5, 25, 30, 40];
    for (final v in ticks) {
      final a = _angle(_t(v));
      final r = radius - stroke / 2 - 16;
      final pos = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      final label = v == 18.5 ? '18.5' : v.toInt().toString();
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // Category captions above the arc
    _caption(canvas, cx, cy, radius + stroke / 2 + 14, 16.75, 'Underweight');
    _caption(canvas, cx, cy, radius + stroke / 2 + 14, 21.75, 'Normal');
    _caption(canvas, cx, cy, radius + stroke / 2 + 14, 27.5, 'Overweight');
    _caption(canvas, cx, cy, radius + stroke / 2 + 14, 35, 'Obesity');

    // Needle
    final a = _angle(_t(bmi.clamp(_min, _max)));
    final tip = Offset(
      cx + (radius - 10) * math.cos(a),
      cy + (radius - 10) * math.sin(a),
    );
    canvas.drawLine(
      Offset(cx, cy),
      tip,
      Paint()
        ..color = const Color(0xFF374151)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
        Offset(cx, cy), 9, Paint()..color = const Color(0xFF374151));
    canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(cx, cy),
      9,
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _caption(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double atBmi,
    String text,
  ) {
    final a = _angle(_t(atBmi));
    final pos = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2937),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  double _t(double value) => ((value - _min) / (_max - _min)).clamp(0.0, 1.0);

  /// Left (π) → top (3π/2) → right (2π). Flutter angles are clockwise.
  double _angle(double t) => math.pi + t * math.pi;

  @override
  bool shouldRepaint(covariant _BmiGaugePainter oldDelegate) =>
      oldDelegate.bmi != bmi || oldDelegate.accent != accent;
}
