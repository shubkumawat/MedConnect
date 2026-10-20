import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../notifications/view/notification_center_screen.dart';
import '../../records/view/health_timeline_screen.dart';
import '../../videos/view/video_reel_player_screen.dart';
import '../../videos/view/video_topic_browser_screen.dart';
import '../controller/home_controller.dart';
import '../widgets/patient_switcher_widget.dart';
import '../widgets/qr_button_widget.dart';
import '../widgets/reminder_strip_widget.dart';
import '../../records/view/disease_list_screen.dart';
import '../../family/view/my_patients_screen.dart';
import '../../profile/view/my_profile_screen.dart';
import '../../records/controller/records_controller.dart';
import '../../family/controller/family_controller.dart';
import '../../find/view/find_doctor_screen.dart';

class HomeDashboardScreen extends GetView<HomeController> {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeContent(),
      const DiseaseListScreen(),
      const FindDoctorScreen(),
      const MyPatientsScreen(),
      const MyProfileScreen(),
    ];

    // Ensure controllers are initialized
    Get.put(RecordsController());
    Get.put(FamilyController());

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.selectedTabIndex.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.primaryDeepBlue,
            selectedItemColor: AppColors.accentTeal,
            unselectedItemColor: Colors.white54,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.description), label: "Records"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Find"),
              BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: "Family"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          )),
      body: Obx(() => IndexedStack(
        index: controller.selectedTabIndex.value,
        children: pages,
      )),
    );
  }
}

class HomeContent extends GetView<HomeController> {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const PatientSwitcherWidget(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Get.to(() => const NotificationCenterScreen()),
          ),
          const QRButtonWidget(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReminderStripWidget(),
            
            _buildSectionHeader("Quick Actions"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickAction(
                    "Health Timeline", 
                    Icons.timeline, 
                    AppColors.primaryDeepBlue, 
                    () => Get.to(() => const HealthTimelineScreen())
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    "Video Tips", 
                    Icons.play_circle_fill, 
                    AppColors.accentTeal.withOpacity(0.2), 
                    () => Get.to(() => const VideoTopicBrowserScreen()),
                    iconColor: AppColors.accentTeal
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("Health Education"),
            const VideoReelsSection(),

            const SizedBox(height: 20),
            _buildSectionHeader("Health Summary"),
            const HealthSummaryCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(title, style: AppTextStyles.poppinsBold18.copyWith(color: Colors.white)),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoReelsSection extends GetView<HomeController> {
  const VideoReelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.videoTopics.length,
            itemBuilder: (context, index) {
              final topic = controller.videoTopics[index];
              final isSelected = controller.selectedTopic.value == topic;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(topic),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) controller.selectTopic(topic);
                  },
                  backgroundColor: AppColors.primaryDeepBlue,
                  selectedColor: AppColors.accentTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryDeepBlue : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          )),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Obx(() => ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.reels.length,
            itemBuilder: (context, index) {
              final reel = controller.reels[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(reel['thumbnail']),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reel['title'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.play_arrow, color: AppColors.accentTeal, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "Watch",
                            style: TextStyle(color: AppColors.accentTeal, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          )),
        ),
      ],
    );
  }
}

class HealthSummaryCard extends StatelessWidget {
  const HealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDeepBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem("Blood Pressure", "120/80", "mmHg", Icons.favorite, Colors.redAccent),
              const Spacer(),
              _buildStatItem("Heart Rate", "72", "bpm", Icons.speed, Colors.orangeAccent),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          Row(
            children: [
              _buildStatItem("Weight", "70.5", "kg", Icons.monitor_weight, Colors.blueAccent),
              const Spacer(),
              _buildStatItem("Sleep", "7.5", "hrs", Icons.bedtime, Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
