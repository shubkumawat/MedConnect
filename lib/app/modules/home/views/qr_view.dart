import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});
  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  int _secondsLeft = 600; // 10 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() => _secondsLeft--);
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _timeString {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft <= 60) return AppColors.statusRed;
    if (_secondsLeft <= 120) return AppColors.orange;
    return AppColors.accentTeal;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Ravi\'s QR Code',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR Code display
            McCard(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Mock QR grid
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _QrPainter(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'RK-2025-PTH356842',
                    style: AppTextStyles.caption.copyWith(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _timerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _timerColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, color: _timerColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$_timeString remaining',
                    style: AppTextStyles.bodyBold.copyWith(color: _timerColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Regenerate
            CustomOutlineButton(
              text: '🔄 Regenerate QR',
              onTap: () => setState(() => _secondsLeft = 600),
              borderColor: AppColors.primary,
              textColor: AppColors.accentBlue,
            ),

            const SizedBox(height: 6),
            Text('Last scanned: Today 3:15 PM', style: AppTextStyles.caption),

            McDivider(margin: const EdgeInsets.symmetric(vertical: 20)),

            // Patient info preview (doctor view)
            McCard(
              color: AppColors.bgCardDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('Doctor View Preview', style: AppTextStyles.heading3),
                    ],
                  ),
                  McDivider(),

                  // Patient details
                  Row(
                    children: [
                      const PatientAvatar(initials: 'RK', color: AppColors.primary, size: 52),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ravi Kumar · 34y · Male', style: AppTextStyles.bodyBold),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              StatusBadge(label: 'B+', color: AppColors.primary),
                              const SizedBox(width: 8),
                              StatusBadge(label: '⚠ Penicillin Allergy', color: AppColors.statusRed),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  McDivider(),

                  _InfoSection(
                    label: 'Active Diseases',
                    value: 'Hernia · Diabetes · Hypertension',
                    color: AppColors.statusActive,
                  ),
                  const SizedBox(height: 10),
                  _InfoSection(
                    label: 'Current Medications',
                    value: 'Metformin 500mg · Amlodipine 5mg',
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 10),
                  _InfoSection(
                    label: 'Emergency Contact',
                    value: 'Priya (Wife): 987-654-3210',
                    color: AppColors.statusRed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String label, value;
  final Color color;

  const _InfoSection({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyles.body.copyWith(color: AppColors.textTail)),
      ],
    );
  }
}

// Simple QR-like grid painter
class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF0D1B3E);
    final s = size.width / 10;

    const pattern = [
      [1,1,1,1,1,1,1,0,1,0],
      [1,0,0,0,0,0,1,0,1,1],
      [1,0,1,1,1,0,1,0,0,0],
      [1,0,1,1,1,0,1,0,1,1],
      [1,0,1,1,1,0,1,1,0,1],
      [1,0,0,0,0,0,1,0,1,0],
      [1,1,1,1,1,1,1,0,0,1],
      [0,0,0,0,0,0,0,0,1,0],
      [0,1,1,0,1,0,1,1,1,1],
      [0,0,1,1,0,1,1,0,1,1],
    ];

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(col * s, row * s, s - 1, s - 1),
            p,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
