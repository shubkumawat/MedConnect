import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../app/routes/app_routes.dart';
import '../model/doctor_model.dart';

class DoctorProfileScreen extends StatelessWidget {
  final DoctorModel? doctor;
  const DoctorProfileScreen({super.key, this.doctor});

  @override
  Widget build(BuildContext context) {
    final DoctorModel selectedDoctor = doctor ?? Get.arguments;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'doctor_${selectedDoctor.id}',
                  child: Container(
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(selectedDoctor.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.backgroundDark.withOpacity(0.8),
                        AppColors.backgroundDark,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Text(
                        selectedDoctor.name,
                        style: AppTextStyles.poppinsBold24.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        selectedDoctor.specialty,
                        style: const TextStyle(color: AppColors.accentTeal, fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard("Experience", selectedDoctor.experience, Icons.work_outline),
                      _buildInfoCard("Rating", selectedDoctor.rating.toString(), Icons.star_outline),
                      _buildInfoCard("Patients", "1.2k+", Icons.people_outline),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "About Doctor",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    selectedDoctor.about,
                    style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Schedules",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: index == 0 ? AppColors.accentTeal : AppColors.primaryDeepBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Oct",
                                style: TextStyle(
                                  color: index == 0 ? AppColors.primaryDeepBlue : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                (24 + index).toString(),
                                style: TextStyle(
                                  color: index == 0 ? AppColors.primaryDeepBlue : Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showBookingSuccess(selectedDoctor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        foregroundColor: AppColors.primaryDeepBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        "Book Appointment",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDeepBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentTeal, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showBookingSuccess(DoctorModel doctor) {
    Get.toNamed(Routes.APPOINTMENT_BOOKING, arguments: doctor);
  }
}
