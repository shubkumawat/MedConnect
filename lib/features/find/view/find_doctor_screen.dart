import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/find_controller.dart';
import 'doctor_profile_screen.dart';
import 'find_hospital_screen.dart';

class FindDoctorScreen extends GetView<FindController> {
  const FindDoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FindController>()) {
      Get.put(FindController());
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text("Find Doctors", style: AppTextStyles.poppinsBold24),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital, color: AppColors.accentTeal),
            onPressed: () => Get.to(() => const FindHospitalScreen()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => controller.updateSearchQuery(value),
              decoration: InputDecoration(
                hintText: "Search Doctors, Specialties...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: AppColors.accentTeal),
                filled: true,
                fillColor: AppColors.primaryDeepBlue,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = controller.filteredDoctors[index];
                    return Card(
                      color: AppColors.primaryDeepBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Hero(
                          tag: 'doctor_${doctor.id}',
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(doctor.imageUrl),
                          ),
                        ),
                        title: Text(
                          doctor.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${doctor.specialty} • ${doctor.experience}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  doctor.rating.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => Get.to(() => DoctorProfileScreen(doctor: doctor)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTeal,
                            foregroundColor: AppColors.primaryDeepBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Book"),
                        ),
                        onTap: () => Get.to(() => DoctorProfileScreen(doctor: doctor)),
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}
