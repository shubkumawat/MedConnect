import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';


import '../../../../DataProvider/api_provider.dart';
import '../../../../DataProvider/app_shared_preferences.dart';
import '../../../../DataProvider/web_api_constant.dart';
import '../../../data/models/video_model.dart';

class VideoSeriesController extends GetxController {

  // index 0 = "All" (trending API se), baaki topics API se
  RxInt selectedTopicIndex = 0.obs;
  // ... existing code ...

  RxBool isTopicsLoading = false.obs;
  RxList<VideoTopicModel> topics = <VideoTopicModel>[].obs;

  RxBool isVideoLoading = false.obs;
  RxList<VideoModel> videos = <VideoModel>[].obs;

  final searchCtrl = TextEditingController();
  RxString searchQuery = ''.obs;

  // Search box me jo type ho raha hai usi se local filter hota hai
  List<VideoModel> get filteredVideos {
    if (searchQuery.value.trim().isEmpty) return videos;
    final q = searchQuery.value.trim().toLowerCase();
    return videos.where((v) {
      return v.title.toLowerCase().contains(q) ||
          v.presenterName.toLowerCase().contains(q) ||
          v.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    searchCtrl.addListener(() {
      searchQuery.value = searchCtrl.text;
    });
    fetchTopics();
    fetchTrendingVideos(); // "All" tab ka default data
  }

  Future<String> _token() async {
    return await AppSharedPreferences().getString(AppSharedPreferences.token) ?? '';
  }

  // ------------------------------------------------------------------
  Future<void> fetchTopics() async {
    try {
      isTopicsLoading.value = true;
      final token = await _token();

      final response = await ApiProvider().getVideoTopicsAPI(
        Get.context,
        WebApiConstant.API_URL_VIDEO_TOPICS,
        {},
        token,
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['topics'] ?? [];
        topics.value = list.map((e) => VideoTopicModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Video Topics Fetch Error: $e");
    } finally {
      isTopicsLoading.value = false;
    }
  }

  // ------------------------------------------------------------------
  Future<void> fetchTrendingVideos() async {
    try {
      isVideoLoading.value = true;
      final token = await _token();

      final response = await ApiProvider().getVideosAPI(
        Get.context,
        WebApiConstant.API_URL_VIDEO_TRENDING,
        {},
        token,
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['videos'] ?? [];
        videos.value = list.map((e) => VideoModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Trending Videos Fetch Error: $e");
    } finally {
      isVideoLoading.value = false;
    }
  }

  // ------------------------------------------------------------------
  Future<void> fetchVideosByTopic(String topicId) async {
    try {
      isVideoLoading.value = true;
      final token = await _token();

      final response = await ApiProvider().getVideosAPI(
        Get.context,
        "${WebApiConstant.API_URL_VIDEO_TOPICS}$topicId/videos/",
        {},
        token,
      );

      if (response != null && response['error'] != true) {
        final List list = response['data']?['results'] ?? [];
        videos.value = list.map((e) => VideoModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("Videos By Topic Fetch Error: $e");
    } finally {
      isVideoLoading.value = false;
    }
  }

  void changeTopic(int index) {
    selectedTopicIndex.value = index;
    searchCtrl.clear();
    if (index == 0) {
      fetchTrendingVideos();
    } else {
      fetchVideosByTopic(topics[index - 1].topicId);
    }
  }

  // ── Video Interactions ──────────────────────────────────────────

  Future<void> toggleLike(VideoModel video) async {
    try {
      final token = await _token();
      final isCurrentlyLiked = video.isLiked;
      
      // Local UI update for immediate feedback
      video.isLiked = !isCurrentlyLiked;
      video.totalLikes = isCurrentlyLiked ? video.totalLikes - 1 : video.totalLikes + 1;
      videos.refresh(); // UI refresh

      if (!isCurrentlyLiked) {
        await ApiProvider().videoLikeAPI(Get.context, video.videoId, token);
      } else {
        await ApiProvider().videoUnlikeAPI(Get.context, video.videoId, token);
      }
    } catch (e) {
      debugPrint("Toggle Like Error: $e");
    }
  }

  Future<void> toggleBookmark(VideoModel video) async {
    try {
      final token = await _token();
      final isCurrentlyBookmarked = video.isBookmarked;

      // Local UI update
      video.isBookmarked = !isCurrentlyBookmarked;
      videos.refresh();

      if (!isCurrentlyBookmarked) {
        await ApiProvider().videoBookmarkAPI(Get.context, video.videoId, token);
      } else {
        await ApiProvider().videoRemoveBookmarkAPI(Get.context, video.videoId, token);
      }
    } catch (e) {
      debugPrint("Toggle Bookmark Error: $e");
    }
  }

  Future<void> shareVideo(VideoModel video) async {
    try {
      final token = await _token();
      // WhatsApp/System Share
      final String text = "Check out this health video: ${video.title}\n${video.videoUrl ?? ''}";
      await Share.share(text);
      
      await ApiProvider().videoShareAPI(Get.context, video.videoId, "whatsapp", token);
    } catch (e) {
      debugPrint("Share Video Error: $e");
    }
  }

  Future<void> updateProgress(String videoId, int position) async {
    try {
      final token = await _token();
      await ApiProvider().videoProgressAPI(Get.context, videoId, {
        "current_position": position,
        "device": "android"
      }, token);
    } catch (e) {
      debugPrint("Update Progress Error: $e");
    }
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}