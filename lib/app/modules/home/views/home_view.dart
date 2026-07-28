import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../../../data/models/video_model.dart';
import '../../../data/services/storage_service.dart';
import '../../family/controllers/family_member_controller.dart';
import '../controllers/home_controller.dart';
import '../../family/views/family_view.dart';
import 'qr_view.dart';
import 'video_series_screen.dart';
import 'notifications_screen.dart';
import '../../family/views/add_family_member_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.tealDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          'Med Connect',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          CustomIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => Get.to(() => const NotificationsScreen()),
            bgColor: Colors.white.withOpacity(0.15),
            iconColor: Colors.white,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchFamilyMembers(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Patient Switcher
                    McCard(
                      padding: const EdgeInsets.all(18),
                      color: AppColors.bgCardNavy,
                      isPremium: true,
                      child: Obx(() {
                        if (controller.isLoading.value && controller.patients.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...List.generate(controller.patients.length, (i) {
                                final member = controller.patients[i];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: GestureDetector(
                                    onTap: () => controller.changePatient(i),
                                    child: PatientAvatar(
                                      initials: controller.getInitials(member.fullName ?? ''),
                                      color: i == 0 ? AppColors.primary : (i == 1 ? AppColors.teal : AppColors.orange),
                                      isActive: controller.activePatientIndex.value == i,
                                      size: 52,
                                      label: member.relation?.name ?? 'Member',
                                    ),
                                  ),
                                );
                              }),
                              GestureDetector(
                                onTap: () async {
                                  final familyController = Get.find<FamilyMemberController>();
                                  familyController.clearFields();
                                  var result = await Get.to(() => const AddFamilyMemberScreen());
                                  if (result == true) {
                                    controller.fetchFamilyMembers();
                                  }
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.border, width: 2),
                                        color: AppColors.bgCardNavy,
                                      ),
                                      child: const Icon(Icons.add, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Add', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Obx(() {
                      if (controller.patients.isEmpty) return const SizedBox();
                      final activeIdx = controller.activePatientIndex.value;
                      if (activeIdx >= controller.patients.length) return const SizedBox();
                      return _buildVitalsCard(context, controller.patients[activeIdx]);
                    }),
                    const SizedBox(height: 20),
                    // Obx(() {
                      // if (!controller.showMedReminders.value && !controller.showVacReminders.value) {
                      //   return const SizedBox.shrink();
                      // }
                      // return
            Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: 'Reminders', actionLabel: 'See all', onAction: () {}),
                          const SizedBox(height: 12),
                          // if (controller.showMedReminders.value)
                            const _ReminderCard(
                              title: 'Paracetamol',
                              subtitle: 'Today, 10:00 AM',
                              borderColor: AppColors.orange,
                              trailing: Icon(Icons.chevron_right, color: AppColors.textGray),
                            ),
                          // if (controller.showMedReminders.value && controller.showVacReminders.value)
                            const SizedBox(height: 12),
                          // if (controller.showVacReminders.value)
                            _ReminderCard(
                              title: 'Flu Shot',
                              subtitle: 'Next Week',
                              borderColor: AppColors.teal,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('PENDING', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 11)),
                              ),
                            ),
                        ],
                      ),
                    // }),
                    const SizedBox(height: 20),
                    SectionHeader(title: 'Health Summary'),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.patients.isEmpty) return const SizedBox();
                      final activeIdx = controller.activePatientIndex.value;
                      if (activeIdx >= controller.patients.length) return const SizedBox();
                      final patient = controller.patients[activeIdx];
                      final medCount = patient.medical?.currentMedications?.length ?? 0;
                      return Row(
                        children: [
                          Expanded(child: StatCard(value: patient.medical?.chronicDisease == true ? '1' : '0', label: 'Diseases', accentColor: AppColors.statusActive, icon: Icons.sick_rounded)),
                          const SizedBox(width: 10),
                          Expanded(child: StatCard(value: medCount.toString(), label: 'Meds', accentColor: AppColors.teal, icon: Icons.medication_rounded)),
                          const SizedBox(width: 10),
                          const Expanded(child: StatCard(value: '0', label: 'Records', accentColor: AppColors.primary, icon: Icons.folder_rounded)),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Obx(() {
                      if (controller.continueWatching.isEmpty) return const SizedBox();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(title: 'Continue Watching'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.continueWatching.length,
                              itemBuilder: (context, index) => _ContinueWatchingCard(video: controller.continueWatching[index]),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
                    SectionHeader(title: 'Health Videos', actionLabel: 'See all', onAction: () => Get.to(() => const VideoSeriesScreen())),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: Obx(() {
                        if (controller.isTopicsLoading.value) return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal)));
                        final labels = controller.topicChipLabels;
                        final selectedIdx = controller.selectedTopicIndex.value;
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: labels.length,
                          itemBuilder: (_, i) => McFilterChip(label: labels[i], isSelected: selectedIdx == i, activeColor: AppColors.orange, onTap: () => controller.changeTopic(i)),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Obx(() {
                if (controller.isVideoLoading.value) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.teal)));
                if (controller.videos.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No videos found')));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.videos.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VideoCard(video: controller.videos[index], onTap: () => Get.to(() => const VideoSeriesScreen())),
                  ),
                );
              }),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context, dynamic patient) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.white, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.tealDark]),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Health Profile', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          Text(patient.fullName ?? 'Guest User', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Get.to(() => QrScreen()),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.appBarColor),
                              color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCardNavy,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),

                border: Border.all(color: AppColors.appBarColor),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
              // String? bloodGroup;
              // String? height;
              // String? weight;
                  _VitalItem(label: 'Blood', value: (patient.bloodGroup?.toString() ?? '--').isEmpty ? '--' : patient.bloodGroup.toString(), icon: Icons.bloodtype_rounded, color: Colors.redAccent),
                  _VitalItem(label: 'Age', value: '${patient.age?.toString() ?? "--"} yrs', icon: Icons.calendar_today, color: AppColors.teal),
                  _VitalItem(label: 'Gender', value: (patient.gender?.toString() ?? "--").isEmpty ? '--' : patient.gender.toString().capitalizeFirst!, icon: Icons.transgender, color: AppColors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _VitalItem({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.bodyBold),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title, subtitle;
  final Color borderColor;
  final Widget trailing;
  const _ReminderCard({required this.title, required this.subtitle, required this.borderColor, required this.trailing});
  @override
  Widget build(BuildContext context) {
    return McCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.bodyBold), Text(subtitle, style: AppTextStyles.caption)])),
          trailing,
        ],
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final VideoModel video;
  const _ContinueWatchingCard({required this.video});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: AppColors.bgCardNavy, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(video.thumbnail ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primary.withOpacity(0.1))),
                  const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(video.title ?? '', style: AppTextStyles.captionBold, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: McCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(video.thumbnail ?? '', width: 100, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 100, height: 70, color: AppColors.primary.withOpacity(0.1))),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(video.title ?? '', style: AppTextStyles.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(video.title ?? '', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis)])),
          ],
        ),
      ),
    );
  }
}
