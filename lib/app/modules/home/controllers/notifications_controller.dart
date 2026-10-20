import 'package:get/get.dart';

import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/inbox_notification_model.dart';
import 'home_controller.dart';

class NotificationsController extends GetxController {
  final items = <InboxNotification>[].obs;
  final loading = false.obs;
  final loadingMore = false.obs;
  final unreadCount = 0.obs;
  final page = 1.obs;
  final hasNext = false.obs;

  static const _pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    fetch(reset: true);
  }

  Future<void> fetch({bool reset = false}) async {
    if (reset) {
      page.value = 1;
      hasNext.value = false;
      loading.value = true;
    } else {
      if (!hasNext.value || loadingMore.value || loading.value) return;
      loadingMore.value = true;
    }

    try {
      final token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);
      final body = <String, dynamic>{
        'page': page.value,
        'page_size': _pageSize,
      };
      if (Get.isRegistered<HomeController>()) {
        final pid = Get.find<HomeController>().selectedPatientId;
        if (pid != null && pid.isNotEmpty) body['patient_id'] = pid;
      }

      final response = await ApiProvider().requestPostForApi(
        Get.context,
        WebApiConstant.API_URL_NOTIFICATIONS_HISTORY,
        body,
        token ?? '',
      );
      final raw = response?.data;
      if (raw is Map && raw['error'] != true && raw['data'] is Map) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        unreadCount.value = int.tryParse('${data['unread_count'] ?? 0}') ?? 0;
        hasNext.value = data['has_next'] == true;
        final list = data['results'] is List ? data['results'] as List : const [];
        final parsed = list
            .whereType<Map>()
            .map((e) => InboxNotification.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.uuid.isNotEmpty || e.title.isNotEmpty)
            .toList();
        if (reset) {
          items.value = parsed;
        } else {
          items.addAll(parsed);
        }
        if (hasNext.value) page.value = page.value + 1;
        return;
      }
      if (reset) items.clear();
    } catch (_) {
      if (reset) items.clear();
    } finally {
      loading.value = false;
      loadingMore.value = false;
    }
  }

  Future<void> loadMore() => fetch(reset: false);
}
