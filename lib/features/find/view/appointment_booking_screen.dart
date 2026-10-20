import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../model/doctor_model.dart';
import '../controller/find_controller.dart';
import '../../home/controller/home_controller.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  final FindController controller = Get.find<FindController>();
  final HomeController homeController = Get.find<HomeController>();
  
  late DoctorModel doctor;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedTime = "10:00 AM";
  String appointmentType = "In-Person";

  final List<String> timeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", "02:00 PM", "03:00 PM", "04:00 PM"
  ];

  @override
  void initState() {
    super.initState();
    doctor = Get.arguments;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text("Book Appointment"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(doctor.imageUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.name, style: AppTextStyles.poppinsSemiBold18.copyWith(color: Colors.white)),
                        Text(doctor.specialty, style: const TextStyle(color: AppColors.accentTeal)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text("Select Date", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildDatePicker(),
            
            const SizedBox(height: 30),
            const Text("Select Time", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildTimeGrid(),
            
            const SizedBox(height: 30),
            const Text("Appointment Type", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildTypeSelector(),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: AppColors.primaryDeepBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Confirm Appointment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index + 1));
          final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
          
          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentTeal : AppColors.primaryDeepBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(color: isSelected ? AppColors.primaryDeepBlue : Colors.white54),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryDeepBlue : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final time = timeSlots[index];
        final isSelected = time == selectedTime;
        
        return GestureDetector(
          onTap: () => setState(() => selectedTime = time),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentTeal : AppColors.primaryDeepBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? AppColors.primaryDeepBlue : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeCard("In-Person", Icons.person_outline),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _typeCard("Video", Icons.videocam_outlined),
        ),
      ],
    );
  }

  Widget _typeCard(String type, IconData icon) {
    final isSelected = appointmentType == type;
    return GestureDetector(
      onTap: () => setState(() => appointmentType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentTeal : AppColors.primaryDeepBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accentTeal : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryDeepBlue : Colors.white54),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? AppColors.primaryDeepBlue : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBooking() {
    Get.defaultDialog(
      title: "Confirm Booking?",
      middleText: "Do you want to book a $appointmentType appointment with ${doctor.name} on ${DateFormat('MMM dd').format(selectedDate)} at $selectedTime?",
      backgroundColor: AppColors.primaryDeepBlue,
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: "Confirm",
      textCancel: "Cancel",
      confirmTextColor: AppColors.primaryDeepBlue,
      buttonColor: AppColors.accentTeal,
      onConfirm: () {
        Get.back(); // Close dialog
        _showSuccess();
      },
    );
  }

  void _showSuccess() {
    Get.defaultDialog(
      title: "Success!",
      middleText: "Your appointment has been booked successfully.",
      backgroundColor: AppColors.primaryDeepBlue,
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      confirm: ElevatedButton(
        onPressed: () {
          Get.until((route) => Get.currentRoute == '/home');
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
        child: const Text("Go to Home", style: TextStyle(color: AppColors.primaryDeepBlue)),
      ),
    );
  }
}
