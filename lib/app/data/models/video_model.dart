/// Video topic - jaisa /videos/topics/ aur /videos/topics/featured/ se aata hai
class VideoTopicModel {
  final String topicId;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String backgroundColor;
  final String? bannerImage;
  final int displayOrder;
  final bool isFeatured;
  final int reelCount;

  VideoTopicModel({
    required this.topicId,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.bannerImage,
    required this.displayOrder,
    required this.isFeatured,
    required this.reelCount,
  });

  factory VideoTopicModel.fromJson(Map<String, dynamic> json) {
    return VideoTopicModel(
      topicId: json['topic_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      backgroundColor: json['background_color']?.toString() ?? '',
      bannerImage: json['banner_image']?.toString(),
      displayOrder: json['display_order'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      reelCount: json['reel_count'] ?? 0,
    );
  }
}

/// Video ke andar chhota nested "topic" object
class VideoTopicMini {
  final String topicId;
  final String name;
  final String icon;
  final String backgroundColor;

  VideoTopicMini({
    required this.topicId,
    required this.name,
    required this.icon,
    required this.backgroundColor,
  });

  factory VideoTopicMini.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return VideoTopicMini(topicId: '', name: '', icon: '', backgroundColor: '');
    }
    return VideoTopicMini(
      topicId: json['topic_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      backgroundColor: json['background_color']?.toString() ?? '',
    );
  }
}

/// Single video - /videos/trending/ aur /videos/topics/{id}/videos/ dono se aata hai
class VideoModel {
  final String videoId;
  final VideoTopicMini topic;
  final String title;
  final String shortDescription;
  final String presenterName;
  final String? thumbnail;
  final String? videoUrl;
  final int duration; // seconds
  final String language;
  final List<String> tags;
  final bool isFeatured;
  final bool allowShare;
  final int totalViews;
  int totalLikes;
  final int totalBookmarks;
  final int totalShares;
  bool isLiked;
  bool isBookmarked;

  VideoModel({
    required this.videoId,
    required this.topic,
    required this.title,
    required this.shortDescription,
    required this.presenterName,
    required this.thumbnail,
    required this.videoUrl,
    required this.duration,
    required this.language,
    required this.tags,
    required this.isFeatured,
    required this.allowShare,
    required this.totalViews,
    required this.totalLikes,
    required this.totalBookmarks,
    required this.totalShares,
    required this.isLiked,
    required this.isBookmarked,
  });

  /// "125" seconds -> "2:05"
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 2100 -> "2.1K views"
  String get formattedViews {
    if (totalViews >= 1000000) {
      return '${(totalViews / 1000000).toStringAsFixed(1)}M views';
    } else if (totalViews >= 1000) {
      return '${(totalViews / 1000).toStringAsFixed(1)}K views';
    }
    return '$totalViews views';
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['video_url']?.toString() ??
        json['video_link']?.toString() ??
        json['url']?.toString() ??
        json['stream_url']?.toString() ??
        json['media_url']?.toString() ??
        '';
    return VideoModel(
      videoId: json['video_id']?.toString() ?? '',
      topic: VideoTopicMini.fromJson(json['topic']),
      title: json['title']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      presenterName: json['presenter_name']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      videoUrl: rawUrl.trim().isEmpty ? null : rawUrl.trim(),
      duration: json['duration'] ?? 0,
      language: json['language']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isFeatured: json['is_featured'] ?? false,
      allowShare: json['allow_share'] ?? true,
      totalViews: json['total_views'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
      totalBookmarks: json['total_bookmarks'] ?? 0,
      totalShares: json['total_shares'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
    );
  }
}