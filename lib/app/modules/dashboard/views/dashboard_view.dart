import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../family/views/family_view.dart';
import '../../find/views/find_view.dart';
import '../../home/views/home_view.dart';
import '../../profile/views/profile_view.dart';
import '../../records/views/records_view.dart';
import '../controllers/dashboard_controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());

    const navItems = [
      _NavItem(icon: Icons.home_rounded, label: 'Home', activeColor: AppColors.teal),
      _NavItem(icon: Icons.medical_services_rounded, label: 'Records', activeColor: AppColors.teal),
      _NavItem(icon: Icons.search_rounded, label: 'Find', activeColor: AppColors.teal),
      _NavItem(icon: Icons.group_rounded, label: 'Family', activeColor: AppColors.teal),
      _NavItem(icon: Icons.person_rounded, label: 'Profile', activeColor: AppColors.teal),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: [
              const RepaintBoundary(child: HomeScreen()),
              RepaintBoundary(
                child: controller.loadedIndices.contains(1)
                    ? const RecordsScreen()
                    : const SizedBox.shrink(),
              ),
              RepaintBoundary(
                child: controller.loadedIndices.contains(2)
                    ? const FindScreen()
                    : const SizedBox.shrink(),
              ),
              RepaintBoundary(
                child: controller.loadedIndices.contains(3)
                    ? const FamilyScreen()
                    : const SizedBox.shrink(),
              ),
              RepaintBoundary(
                child: controller.loadedIndices.contains(4)
                    ? const ProfileScreen()
                    : const SizedBox.shrink(),
              ),
            ],
          )),
      bottomNavigationBar: Container(
        height: 90,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (i) {
            final item = navItems[i];
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.changeIndex(i),
                  borderRadius: BorderRadius.circular(28),
                  child: Obx(() {
                    final isActive = controller.currentIndex.value == i;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.ease,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? item.activeColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textMuted.withValues(alpha: 0.8),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: AppMotion.fast,
                            curve: AppMotion.ease,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w600,
                              color: isActive
                                  ? item.activeColor
                                  : AppColors.textMuted.withValues(alpha: 0.8),
                            ),
                            child: Text(item.label),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  const _NavItem({required this.icon, required this.label, required this.activeColor});
}
