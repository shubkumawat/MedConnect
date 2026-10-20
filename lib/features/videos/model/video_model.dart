class VideoModel {
  final String id;
  final String title;
  final String topic;
  final String videoUrl;
  final String thumbnailUrl;
  final String physicianName;
  final String duration;

  VideoModel({
    required this.id,
    required this.title,
    required this.topic,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.physicianName,
    required this.duration,
  });
}
