import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healora/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healora/app/data/models/inbox_notification_model.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController controller;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());
    controller.fetch(reset: true);
    _scroll.addListener(() {
      if (_scroll.position.pixels >
          _scroll.position.maxScrollExtent - 240) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: 'Notifications',
        showBack: true,
        actions: [
          Obx(() {
            final n = controller.unreadCount.value;
            if (n <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '$n unread',
                  style: AppTextStyles.captionBold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.items.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }
        if (controller.items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.teal,
            onRefresh: () => controller.fetch(reset: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                const Icon(Icons.notifications_none_rounded,
                    size: 48, color: AppColors.textGray),
                const SizedBox(height: 12),
                Text(
                  'No notifications yet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 6),
                Text(
                  'Medication and care reminders will show up here.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          );
        }

        final today = <InboxNotification>[];
        final earlier = <InboxNotification>[];
        final now = DateTime.now();
        for (final n in controller.items) {
          final d = n.createdAt?.toLocal();
          if (d != null &&
              d.year == now.year &&
              d.month == now.month &&
              d.day == now.day) {
            today.add(n);
          } else {
            earlier.add(n);
          }
        }

        return RefreshIndicator(
          color: AppColors.teal,
          onRefresh: () => controller.fetch(reset: true),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              if (today.isNotEmpty) ...[
                _SectionLabel('Today'),
                const SizedBox(height: 10),
                ...today.map(_InboxTile.new),
                const SizedBox(height: 16),
              ],
              if (earlier.isNotEmpty) ...[
                _SectionLabel('Earlier'),
                const SizedBox(height: 10),
                ...earlier.map(_InboxTile.new),
              ],
              if (controller.loadingMore.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.captionBold.copyWith(color: AppColors.accentTeal),
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final InboxNotification item;
  const _InboxTile(this.item);

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final style = _styleFor(item.type, item.sourceType);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread
            ? AppColors.orange.withValues(alpha: 0.1)
            : AppColors.bgCardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unread ? AppColors.orange : AppColors.border,
          width: unread ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: style.$2.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.$1, color: style.$2, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                if (item.body.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
                if (item.typeLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.typeLabel,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.tealDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeLabel(item.createdAt),
                style: AppTextStyles.caption,
              ),
              if (unread) ...[
                const SizedBox(height: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static (IconData, Color) _styleFor(String type, String source) {
    final key = '${type}_$source'.toLowerCase();
    if (key.contains('medication')) {
      return (Icons.medication_rounded, AppColors.orange);
    }
    if (key.contains('vaccin')) {
      return (Icons.vaccines_rounded, AppColors.teal);
    }
    if (key.contains('qr')) {
      return (Icons.qr_code_scanner_rounded, AppColors.primary);
    }
    if (key.contains('appointment') || key.contains('event')) {
      return (Icons.event_rounded, AppColors.accentBlue);
    }
    return (Icons.notifications_rounded, AppColors.accentTeal);
  }

  static String _timeLabel(DateTime? raw) {
    if (raw == null) return '';
    final d = raw.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return DateFormat.jm().format(d);
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('d MMM').format(d);
  }
}
