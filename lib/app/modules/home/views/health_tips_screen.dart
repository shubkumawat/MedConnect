import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/health_tips_controller.dart';
import 'package:healora/app/core/Util/app_toast.dart';

enum TipCategory {
  all,
  today,
  nutrition,
  fitness,
  sleep,
  mental,
  prevention,
  lifestyle,
  hydration,
}

extension TipCategoryX on TipCategory {
  String get label {
    switch (this) {
      case TipCategory.all:
        return 'All';
      case TipCategory.today:
        return "Today's Tip";
      case TipCategory.nutrition:
        return 'Nutrition';
      case TipCategory.fitness:
        return 'Fitness';
      case TipCategory.sleep:
        return 'Sleep';
      case TipCategory.mental:
        return 'Mental Health';
      case TipCategory.prevention:
        return 'Prevention';
      case TipCategory.lifestyle:
        return 'Lifestyle';
      case TipCategory.hydration:
        return 'Hydration';
    }
  }

  String? get apiValue {
    switch (this) {
      case TipCategory.all:
      case TipCategory.today:
        return null;
      default:
        return name;
    }
  }

  static TipCategory fromApi(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'fitness':
        return TipCategory.fitness;
      case 'sleep':
        return TipCategory.sleep;
      case 'mental':
        return TipCategory.mental;
      case 'prevention':
      case 'preventive':
        return TipCategory.prevention;
      case 'lifestyle':
      case 'seasonal':
        return TipCategory.lifestyle;
      case 'hydration':
        return TipCategory.hydration;
      default:
        return TipCategory.nutrition;
    }
  }
}

class HealthTip {
  final String id;
  final String uuid;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final TipCategory category;
  final bool isToday;
  final bool isHelpful;

  const HealthTip({
    required this.id,
    this.uuid = '',
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.category,
    this.isToday = false,
    this.isHelpful = false,
  });

  HealthTip copyWith({bool? isHelpful, bool? isToday}) {
    return HealthTip(
      id: id,
      uuid: uuid,
      title: title,
      body: body,
      icon: icon,
      color: color,
      category: category,
      isToday: isToday ?? this.isToday,
      isHelpful: isHelpful ?? this.isHelpful,
    );
  }

  static IconData iconFor(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'walk':
      case 'directions_walk':
        return Icons.directions_walk_rounded;
      case 'bedtime':
      case 'sleep':
        return Icons.bedtime_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'clean_hands':
        return Icons.clean_hands_rounded;
      case 'umbrella':
        return Icons.umbrella_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'lightbulb':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }

  static Color colorFor(String raw) {
    var hex = raw.trim().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final n = int.tryParse(hex, radix: 16);
    if (n == null) return const Color(0xFF1B9E8E);
    return Color(n);
  }

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    final uuid = (json['uuid'] ?? '').toString();
    final slug = (json['slug'] ?? json['id'] ?? uuid).toString();
    return HealthTip(
      id: slug.isNotEmpty ? slug : uuid,
      uuid: uuid,
      title: json['title']?.toString() ?? '',
      body: (json['body'] ?? json['short_body'] ?? '').toString(),
      icon: iconFor(json['icon']?.toString() ?? ''),
      color: colorFor(json['color_hex']?.toString() ?? '#1B9E8E'),
      category: TipCategoryX.fromApi(json['category']?.toString() ?? ''),
      isToday: json['is_today'] == true,
      isHelpful: json['is_helpful'] == true,
    );
  }
}

const List<HealthTip> kHealthTips = [
  HealthTip(
    id: 'hydrate',
    title: 'Stay hydrated',
    body:
        'Drink 7–8 glasses of water daily. Proper hydration supports energy, kidneys and focus. Start your morning with a glass before coffee or tea.',
    icon: Icons.water_drop_rounded,
    color: Color(0xFF1B9E8E),
    category: TipCategory.nutrition,
    isToday: true,
  ),
  HealthTip(
    id: 'move',
    title: 'Move every hour',
    body:
        'Stand up and stretch for 2–3 minutes every hour if you sit for long stretches. Short walks after meals also help blood sugar stay steady.',
    icon: Icons.directions_walk_rounded,
    color: Color(0xFFE07B2A),
    category: TipCategory.fitness,
  ),
  HealthTip(
    id: 'sleep',
    title: 'Sleep 7–8 hours',
    body:
        'Consistent sleep strengthens immunity and helps blood pressure stay in a healthy range. Keep screens away for 30 minutes before bed.',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF0B6E4F),
    category: TipCategory.mental,
  ),
  HealthTip(
    id: 'vitals',
    title: 'Know your vitals',
    body:
        'Keep blood group, allergies and emergency contacts updated in Healora for faster care when every second counts.',
    icon: Icons.favorite_rounded,
    color: Color(0xFFC62828),
    category: TipCategory.prevention,
  ),
  HealthTip(
    id: 'protein',
    title: 'Add protein to every meal',
    body:
        'Include dal, eggs, curd or paneer with meals to stay fuller longer and support muscle recovery after activity.',
    icon: Icons.restaurant_rounded,
    color: Color(0xFF2E7D32),
    category: TipCategory.nutrition,
  ),
  HealthTip(
    id: 'breath',
    title: 'Box breathing break',
    body:
        'Inhale 4 counts, hold 4, exhale 4, hold 4. Repeat for one minute when stress rises — a calm nervous system helps heart rate settle.',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF5C6BC0),
    category: TipCategory.mental,
  ),
  HealthTip(
    id: 'handwash',
    title: 'Wash hands often',
    body:
        '20 seconds of handwashing before meals and after outdoors cuts infection risk. Carry a small sanitizer when water is unavailable.',
    icon: Icons.clean_hands_rounded,
    color: Color(0xFF00897B),
    category: TipCategory.prevention,
  ),
  HealthTip(
    id: 'monsoon',
    title: 'Monsoon mosquito check',
    body:
        'Empty stagnant water around home weekly. Use nets or repellents in the evening when mosquito activity rises.',
    icon: Icons.umbrella_rounded,
    color: Color(0xFF546E7A),
    category: TipCategory.lifestyle,
  ),
  HealthTip(
    id: 'strength',
    title: 'Two strength sessions weekly',
    body:
        'Bodyweight squats, wall push-ups or light weights twice a week protect joints and bone density as you age.',
    icon: Icons.fitness_center_rounded,
    color: Color(0xFFEF6C00),
    category: TipCategory.fitness,
  ),
];

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  TipCategory _tab = TipCategory.all;
  final Set<String> _expanded = {};
  late final HealthTipsController _tips;

  @override
  void initState() {
    super.initState();
    _tips = Get.isRegistered<HealthTipsController>()
        ? Get.find<HealthTipsController>()
        : Get.put(HealthTipsController());
    _tips.fetch();
  }

  List<HealthTip> get _filtered {
    final all = _tips.tips.isNotEmpty ? _tips.tips : kHealthTips;
    switch (_tab) {
      case TipCategory.all:
        return all;
      case TipCategory.today:
        final today = all.where((t) => t.isToday).toList();
        if (today.isNotEmpty) return today;
        if (_tips.today.value != null) return [_tips.today.value!];
        return all.take(1).toList();
      default:
        return all.where((t) => t.category == _tab).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Tips',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Curated daily health content',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: TipCategory.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = TipCategory.values[i];
                final active = _tab == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() => _tab = cat);
                    _tips.fetch(category: cat.apiValue);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.tealDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : const Color(0xFFE3EBE7),
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              final tips = _filtered;
              if (_tips.loading.value && _tips.tips.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                );
              }
              if (tips.isEmpty) {
                return Center(
                  child: Text(
                    'No tips in this category yet',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textGray),
                  ),
                );
              }
              return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    itemCount: tips.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final tip = tips[i];
                      final expanded = _expanded.contains(tip.id);
                      final helpful = tip.isHelpful;
                      return _TipCard(
                        tip: tip,
                        expanded: expanded,
                        helpful: helpful,
                        onToggleExpand: () {
                          setState(() {
                            if (expanded) {
                              _expanded.remove(tip.id);
                            } else {
                              _expanded.add(tip.id);
                            }
                          });
                        },
                        onMarkHelpful: () async {
                          await _tips.toggleHelpful(tip);
                          _tips.tips.value = _tips.tips
                              .map((t) => t.id == tip.id
                                  ? t.copyWith(isHelpful: !helpful)
                                  : t)
                              .toList();
                          AppToast.showToast(
                            msg: helpful
                                ? 'Removed from helpful'
                                : 'Marked as helpful — thanks!',
                          );
                        },
                      )
                          .animate()
                          .fadeIn(delay: (40 * i).ms, duration: 280.ms)
                          .slideY(begin: 0.04, end: 0);
                    },
                  );
            }),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final HealthTip tip;
  final bool expanded;
  final bool helpful;
  final VoidCallback onToggleExpand;
  final VoidCallback onMarkHelpful;

  const _TipCard({
    required this.tip,
    required this.expanded,
    required this.helpful,
    required this.onToggleExpand,
    required this.onMarkHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onToggleExpand,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tip.color.withValues(alpha: 0.22)),
            gradient: LinearGradient(
              colors: [
                tip.color.withValues(alpha: 0.10),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tip.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tip.icon, color: tip.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tip.title,
                                style: AppTextStyles.heading3.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (tip.isToday)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tip.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: tip.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tip.category.label,
                          style: TextStyle(
                            color: tip.color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tip.body,
                maxLines: expanded ? null : 2,
                overflow:
                    expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textGray,
                  height: 1.4,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    expanded ? 'Show less' : 'Read more',
                    style: TextStyle(
                      color: tip.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: tip.color,
                    size: 18,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onMarkHelpful,
                    icon: Icon(
                      helpful
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: helpful ? AppColors.tealDark : AppColors.textGray,
                    ),
                    label: Text(
                      helpful ? 'Helpful' : 'Mark Helpful',
                      style: TextStyle(
                        color:
                            helpful ? AppColors.tealDark : AppColors.textGray,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
