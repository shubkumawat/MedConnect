import 'package:get/get.dart';
import '../../family/model/family_member_model.dart';

class HomeController extends GetxController {
  var selectedTabIndex = 0.obs;
  
  // Active Patient
  var activePatient = Rxn<FamilyMemberModel>();
  
  // Reminders dummy data
  var reminders = <Map<String, dynamic>>[
    {'icon': '💊', 'time': '09:00 AM', 'title': 'Metformin', 'desc': '500mg - After Breakfast'},
    {'icon': '💉', 'time': '11:30 AM', 'title': 'Flu Shot', 'desc': 'City Hospital'},
    {'icon': '💊', 'time': '02:00 PM', 'title': 'Vitamin D', 'desc': '1000 IU'},
  ].obs;

  // Video Topics
  var videoTopics = ['Heart Health', 'Diabetes', 'Fitness', 'Nutrition', 'Mental Health'].obs;
  var selectedTopic = 'Heart Health'.obs;

  // Reels dummy data
  var reels = <Map<String, dynamic>>[
    {'title': 'Understanding BPM', 'thumbnail': 'https://picsum.photos/200/300?sig=1'},
    {'title': 'Cardio Basics', 'thumbnail': 'https://picsum.photos/200/300?sig=2'},
    {'title': 'Healthy Heart Diet', 'thumbnail': 'https://picsum.photos/200/300?sig=3'},
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // Default patient
    activePatient.value = FamilyMemberModel(
      id: '1',
      name: 'John Doe',
      relation: 'Self',
      bloodGroup: 'O+',
    );
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  void switchPatient(FamilyMemberModel patient) {
    activePatient.value = patient;
  }

  void selectTopic(String topic) {
    selectedTopic.value = topic;
    // Update reels based on topic (dummy logic)
    reels.value = [
      {'title': '$topic Tip 1', 'thumbnail': 'https://picsum.photos/200/300?sig=${topic.length + 1}'},
      {'title': '$topic Tip 2', 'thumbnail': 'https://picsum.photos/200/300?sig=${topic.length + 2}'},
    ];
  }
}
