import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../views/health_tips_screen.dart';

class HealthTipsController extends GetxController {
  final tips = <HealthTip>[].obs;
  final today = Rxn<HealthTip>();
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch({String? category}) async {
    try {
      loading.value = true;
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final q = <String, dynamic>{};
      if (category != null &&
          category.isNotEmpty &&
          category != 'all' &&
          category != 'today') {
        q['category'] = category;
      }
      final response = await ApiProvider().requestGetForApi(
        Get.context,
        WebApiConstant.API_URL_HEALTH_TIPS,
        q,
        token ?? '',
      );
      final raw = response?.data;
      if (raw is Map && raw['error'] != true) {
        final data = raw['data'];
        List list = const [];
        HealthTip? todayTip;
        if (data is Map) {
          if (data['results'] is List) list = data['results'] as List;
          if (data['today'] is Map) {
            todayTip = HealthTip.fromJson(
              Map<String, dynamic>.from(data['today'] as Map),
            );
          }
        } else if (data is List) {
          list = data;
        }
        final parsed = list
            .whereType<Map>()
            .map((e) => HealthTip.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) {
          tips.value = parsed;
          today.value = todayTip ??
              parsed.firstWhereOrNull((e) => e.isToday) ??
              parsed.first;
          return;
        }
      }
      if (tips.isEmpty) {
        tips.value = kHealthTips;
        today.value = kHealthTips.firstWhereOrNull((e) => e.isToday) ??
            kHealthTips.first;
      }
    } catch (_) {
      if (tips.isEmpty) {
        tips.value = kHealthTips;
        today.value = kHealthTips.firstWhereOrNull((e) => e.isToday) ??
            kHealthTips.first;
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> toggleHelpful(HealthTip tip) async {
    try {
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_HEALTH_TIPS_HELPFUL,
        {'uuid': tip.uuid.isNotEmpty ? tip.uuid : tip.id},
        token ?? '',
      );
    } catch (_) {}
  }
}
