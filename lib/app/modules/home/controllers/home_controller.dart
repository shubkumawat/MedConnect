import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/family_member_model.dart';
import '../../../data/models/video_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/storage_service.dart';

class HomeController extends GetxController {
  
  var activePatientIndex = 0.obs;
  var isLoading = false.obs;

  RxList<FamilyMember> patients = <FamilyMember>[].obs;

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
    fetchFamilyMembers();
    fetchVideoTopics();
    fetchTrendingVideos();
    loadHistoryLists(); 
    loadReminderSettings();
  }

  Future<void> loadReminderSettings() async {
    final storage = StorageService();
    showMedReminders.value = await storage.getBool(StorageService.medReminders);
    showVacReminders.value = await storage.getBool(StorageService.vacReminders);
  }

  Future<void> fetchFamilyMembers() async {
    try {
      isLoading.value = true;
      String? token = await AppSharedPreferences().getString(AppSharedPreferences.token);

      final response = await ApiProvider().getFamilyMemberListAPI(
        Get.context,
        WebApiConstant.API_URL_FAMILY_MEMBER_LIST,
        {},
        token ?? '',
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['family_members'] ?? [];
        patients.value = list.map((e) => FamilyMember.fromJson(e)).toList();
        patients.refresh();
      }
    } catch (e) {
      print("Home Fetch Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void changePatient(int index) {
    activePatientIndex.value = index;
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
