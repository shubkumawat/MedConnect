import 'package:get/get.dart';
import '../model/video_model.dart';

class VideoController extends GetxController {
  var topics = ["Mental Health", "Nutrition", "Exercise", "Sleep", "Heart Health", "First Aid"].obs;
  var selectedTopic = "".obs;
  var reels = <VideoModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadReels();
  }

  void _loadReels() {
    reels.value = [
      VideoModel(
        id: '1',
        title: 'Morning Yoga Stretches',
        topic: 'Exercise',
        videoUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        thumbnailUrl: 'https://picsum.photos/400/800?sig=1',
        physicianName: 'Dr. Sarah Lee',
        duration: '00:59',
      ),
      VideoModel(
        id: '2',
        title: 'Managing Stress at Work',
        topic: 'Mental Health',
        videoUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        thumbnailUrl: 'https://picsum.photos/400/800?sig=2',
        physicianName: 'Dr. John Smith',
        duration: '00:45',
      ),
      VideoModel(
        id: '3',
        title: 'Heart Healthy Foods',
        topic: 'Heart Health',
        videoUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        thumbnailUrl: 'https://picsum.photos/400/800?sig=3',
        physicianName: 'Dr. Emily Brown',
        duration: '01:15',
      ),
    ];
  }

  void selectTopic(String topic) {
    selectedTopic.value = topic;
    // In a real app, this would trigger a network request
  }
}
