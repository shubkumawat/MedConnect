import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/family_member_model.dart';
import '../../../data/models/video_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/storage_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../records/controllers/records_controller.dart';

int access_type = 0;
class HomeController extends GetxController {
  
  var activePatientIndex = 0.obs;
  var isLoading = false.obs;

  RxList<FamilyMember> patients = <FamilyMember>[].obs;

  FamilyMember? get selectedPatient {
    if (patients.isEmpty) return null;
    final i = activePatientIndex.value.clamp(0, patients.length - 1);
    return patients[i];
  }

  String? get selectedPatientId {
    final id = selectedPatient?.patientId?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  // Reminders Visibility
  RxBool showMedReminders = true.obs;
  RxBool showVacReminders = true.obs;

  // Video State
  var selectedTopicIndex = 0.obs;
  RxBool isTopicsLoading = false.obs;
  RxList<VideoTopicModel> videoTopics = <VideoTopicModel>[].obs;

  RxBool isVideoLoading = false.obs;
  RxList<VideoModel> videos = <VideoModel>[].obs;

  // History/Saved Lists
  RxList<VideoModel> savedVideos = <VideoModel>[].obs;
  RxList<VideoModel> historyVideos = <VideoModel>[].obs;
  RxList<VideoModel> continueWatching = <VideoModel>[].obs;

  List<String> get topicChipLabels => ['🔥 Trending', ...videoTopics.map((t) => t.name)];

  @override
  void onInit() {
    super.onInit();
    _initialLoad();
    loadReminderSettings();
  }

  Future<void> _initialLoad() async {
    // Phase 1: Critical UI data
    await fetchFamilyMembers();
    
    // Phase 2: Deferred loading for better performance
    Future.delayed(const Duration(milliseconds: 300), () {
      fetchVideoTopics();
      fetchTrendingVideos();
    });

    // Phase 3: Secondary data
    Future.delayed(const Duration(milliseconds: 600), () {
      loadHistoryLists();
    });
  }

  Future<void> loadReminderSettings() async {
    final storage = StorageService();
    showMedReminders.value = await storage.getBool(StorageService.medReminders);
    showVacReminders.value = await storage.getBool(StorageService.vacReminders);
  }

  Future<void> fetchFamilyMembers() async {
    try {
      isLoading.value = true;
      String? token =
          await AppSharedPreferences().getString(AppSharedPreferences.token);

      // Own profile first (patients/profile/), then family members.
      FamilyMember? self;
      try {
        final profileRes = await ApiProvider().requestGetForApi(
          Get.context,
          WebApiConstant.API_URL_PATIENT_PROFILE,
          {},
          token ?? '',
        );
        if (profileRes != null &&
            profileRes.statusCode == 200 &&
            profileRes.data is Map) {
          final body = Map<String, dynamic>.from(profileRes.data as Map);
          if (body['error'] != true && body['data'] is Map) {
            self = FamilyMember.fromProfileJson(
              Map<String, dynamic>.from(body['data'] as Map),
            );
          }
        }
      } catch (e) {
        print('Home self profile error: $e');
      }

      final response = await ApiProvider().getFamilyMemberListAPI(
        Get.context,
        WebApiConstant.API_URL_FAMILY_MEMBER_LIST,
        {},
        token ?? '',
      );

      // Family members — same list parsing as before.
      final family = <FamilyMember>[];
      if (response != null && response['error'] != true) {
        final List list = response['data']?['family_members'] ?? [];
        family.addAll(list.map((e) => FamilyMember.fromJson(e)).toList());
      }

      // Passport order: Me (profile API) first, then family as-is.
      final members = <FamilyMember>[];
      if (self != null) {
        members.add(self);
        final selfId = self.patientId?.trim();
        if (selfId != null && selfId.isNotEmpty) {
          family.removeWhere((m) => m.patientId?.trim() == selfId);
        }
      }
      members.addAll(family);

      patients.value = members;
      await _restoreSelectedPatient();
      patients.refresh();
    } catch (e) {
      print("Home Fetch Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _restoreSelectedPatient() async {
    if (patients.isEmpty) {
      activePatientIndex.value = 0;
      return;
    }
    final saved =
        await StorageService().getString(StorageService.selectedPatientId);
    if (saved.trim().isNotEmpty) {
      final i = patients.indexWhere(
        (p) => (p.patientId?.trim() ?? '') == saved.trim(),
      );
      if (i > 0) {
        final member = patients.removeAt(i);
        patients.insert(0, member);
      }
    }
    // Selected member always lives at the front of the passport.
    activePatientIndex.value = 0;
    final member = selectedPatient;
    final id = member?.patientId?.trim() ?? '';
    if (id.isNotEmpty) {
      await StorageService().setString(StorageService.selectedPatientId, id);
    }
    // Keep Records in sync with the passport card that is selected.
    _syncRecordsSelection(member, refreshIfChanged: true);
  }

  /// Select by tap only (not scroll). Moves that member to first position.
  void changePatient(int index) {
    if (patients.isEmpty) return;
    final i = index.clamp(0, patients.length - 1);
    if (i != 0) {
      final moved = patients.removeAt(i);
      patients.insert(0, moved);
    }
    activePatientIndex.value = 0;
    final member = patients[0];
    final id = member.patientId?.trim() ?? '';
    StorageService().setString(StorageService.selectedPatientId, id);
    _syncRecordsSelection(member, refreshIfChanged: true);
  }

  void _syncRecordsSelection(
    FamilyMember? member, {
    bool refreshIfChanged = false,
  }) {
    if (member == null || !Get.isRegistered<RecordsController>()) return;
    final records = Get.find<RecordsController>();
    final nextId = member.patientId?.trim() ?? '';
    final changed = records.selectedPatientId.value.trim() != nextId;
    records.applySelectedMember(member);
    if (!refreshIfChanged || !changed) return;

    // Refresh immediately if Records tab is open; otherwise next open will refresh.
    final onRecords = Get.isRegistered<DashboardController>() &&
        Get.find<DashboardController>().currentIndex.value == 1;
    if (onRecords) {
      records.refreshForSelectedPatient();
    }
  }

  void selectPatientById(String? patientId) {
    if (patientId == null || patientId.trim().isEmpty || patients.isEmpty) {
      return;
    }
    final i = patients.indexWhere(
      (p) => (p.patientId?.trim() ?? '') == patientId.trim(),
    );
    if (i >= 0) changePatient(i);
  }

  /// Select member (by index or id) and open Records for that patient.
  Future<void> openRecordsForSelected({
    int? index,
    String? patientId,
    FamilyMember? member,
  }) async {
    if (index != null) {
      changePatient(index);
      // changePatient moves the member to index 0.
      member ??= patients.isNotEmpty ? patients[0] : null;
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      final id = patientId.trim();
      await StorageService().setString(StorageService.selectedPatientId, id);
      if (patients.isEmpty) {
        await fetchFamilyMembers();
      }
      selectPatientById(id);
      member ??= patients.firstWhereOrNull(
        (p) => (p.patientId?.trim() ?? '') == id,
      );
    }

    if (member != null && Get.isRegistered<RecordsController>()) {
      Get.find<RecordsController>().applySelectedMember(member);
    }

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeIndex(1);
    }
  }

  // ----------------------- Video APIs -----------------------

  Future<void> fetchVideoTopics() async {
    try {
      isTopicsLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final response = await ApiProvider().getVideoTopicsAPI(
        Get.context,
        WebApiConstant.API_URL_VIDEO_TOPICS,
        {},
        token ?? '',
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['topics'] ?? [];
        videoTopics.value = list.map((e) => VideoTopicModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Video Topics Error: $e");
    } finally {
      isTopicsLoading.value = false;
    }
  }

  Future<void> fetchTrendingVideos() async {
    try {
      isVideoLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final response = await ApiProvider().getVideosAPI(
        Get.context,
        WebApiConstant.API_URL_VIDEO_TRENDING,
        {},
        token ?? '',
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['videos'] ?? [];
        videos.value = list.map((e) => VideoModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Trending Error: $e");
    } finally {
      isVideoLoading.value = false;
    }
  }

  Future<void> fetchVideosByTopic(String topicId) async {
    try {
      isVideoLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final response = await ApiProvider().getVideosAPI(
        Get.context,
        "${WebApiConstant.API_URL_VIDEO_BY_TOPIC}$topicId/videos/",
        {},
        token ?? '',
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['results'] ?? [];
        videos.value = list.map((e) => VideoModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Topic Videos Error: $e");
    } finally {
      isVideoLoading.value = false;
    }
  }

  void changeTopic(int index) {
    selectedTopicIndex.value = index;
    if (index == 0) {
      fetchTrendingVideos();
    } else {
      final topic = videoTopics[index - 1];
      if (topic.topicId != null) fetchVideosByTopic(topic.topicId!);
    }
  }

  // ----------------------- Interactions (All Call) -----------------------

  Future<void> toggleLike(String videoId) async {
    try {
      final token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final index = videos.indexWhere((v) => v.videoId == videoId);
      
      if (index != -1) {
        final video = videos[index];
        final isCurrentlyLiked = video.isLiked;
        
        // Local Update
        video.isLiked = !isCurrentlyLiked;
        video.totalLikes = isCurrentlyLiked ? video.totalLikes - 1 : video.totalLikes + 1;
        videos.refresh();

        if (!isCurrentlyLiked) {
          await ApiProvider().videoLikeAPI(Get.context, videoId, token ?? '');
        } else {
          await ApiProvider().videoUnlikeAPI(Get.context, videoId, token ?? '');
        }
      }
    } catch (e) {
      print("Toggle Like Error: $e");
    }
  }

  Future<void> bookmarkVideo(String videoId) async {
    try {
      final token = await AppSharedPreferences().getString(AppSharedPreferences.token);
      final index = videos.indexWhere((v) => v.videoId == videoId);
      
      if (index != -1) {
        final video = videos[index];
        final isCurrentlyBookmarked = video.isBookmarked;

        // Local Update
        video.isBookmarked = !isCurrentlyBookmarked;
        videos.refresh();

        if (!isCurrentlyBookmarked) {
          await ApiProvider().videoBookmarkAPI(Get.context, videoId, token ?? '');
        } else {
          await ApiProvider().videoRemoveBookmarkAPI(Get.context, videoId, token ?? '');
        }
      }
    } catch (e) {
      print("Bookmark Error: $e");
    }
  }

  Future<void> shareVideo(String videoId, {String platform = "whatsapp"}) async {
    String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
    final response = await ApiProvider().videoShareAPI(Get.context, videoId, platform, token ?? '');
    if (response != null) Get.snackbar("Share", "Success");
  }

  Future<void> updateProgress(String videoId, int position, int total) async {
    String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
    await ApiProvider().videoProgressAPI(Get.context, videoId, {
      "current_position": position,
      "watch_time": position,
      "device": "android"
    }, token ?? '');
  }

  Future<void> reportVideo(String videoId, String reason, String comment) async {
    String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
    final response = await ApiProvider().videoReportAPI(Get.context, videoId, reason, comment, token ?? '');
    if (response != null) Get.snackbar("Report", "Submitted successfully");
  }

  // ----------------------- Fetching History/Saved -----------------------

  Future<void> loadHistoryLists() async {
    String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);
    if (token == null) return;

    // Continue Watching
    final cwRes = await ApiProvider().getContinueWatchingAPI(Get.context, token);
    if (cwRes != null) {
      final List list = cwRes['data']?['videos'] ?? [];
      continueWatching.value = list.map((e) => VideoModel.fromJson(e)).toList();
    }

    // Saved
    final sRes = await ApiProvider().getSavedVideosAPI(Get.context, token);
    if (sRes != null) {
      final List list = sRes['data']?['videos'] ?? [];
      savedVideos.value = list.map((e) => VideoModel.fromJson(e)).toList();
    }

    // History
    final hRes = await ApiProvider().getVideoHistoryAPI(Get.context, token);
    if (hRes != null) {
      final List list = hRes['data']?['videos'] ?? [];
      historyVideos.value = list.map((e) => VideoModel.fromJson(e)).toList();
    }
  }

  String getInitials(String name) {
    if (name.isEmpty) return '??';
    List<String> names = name.split(" ");
    return names.length > 1 ? names[0][0] + names[1][0] : names[0][0];
  }
}
