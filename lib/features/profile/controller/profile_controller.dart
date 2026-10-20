import 'package:get/get.dart';
import '../model/health_tip_model.dart';
import '../model/emergency_contact_model.dart';

class ProfileController extends GetxController {
  var healthTips = <HealthTipModel>[].obs;
  var emergencyContacts = <EmergencyContactModel>[].obs;
  var userName = "John Doe".obs;
  var userEmail = "john.doe@example.com".obs;

  @override
  void onInit() {
    super.onInit();
    _loadHealthTips();
    _loadEmergencyContacts();
  }

  void _loadHealthTips() {
    healthTips.value = [
      HealthTipModel(
        id: '1',
        title: 'Stay Hydrated!',
        description: 'Drinking at least 8 glasses of water a day helps maintain energy levels and brain function. It also keeps your skin glowing and aids in digestion.',
        imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf3d?q=80&w=400&auto=format&fit=crop',
        category: 'Lifestyle',
      ),
      HealthTipModel(
        id: '2',
        title: 'Better Sleep Habits',
        description: 'Try to maintain a consistent sleep schedule even on weekends. Avoid screens 30 minutes before bed to improve sleep quality.',
        imageUrl: 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?q=80&w=400&auto=format&fit=crop',
        category: 'Mental Health',
      ),
      HealthTipModel(
        id: '3',
        title: 'Importance of Cardio',
        description: 'Just 30 minutes of brisk walking every day can significantly reduce the risk of heart disease and improve your mood.',
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?q=80&w=400&auto=format&fit=crop',
        category: 'Fitness',
      ),
    ];
  }

  void _loadEmergencyContacts() {
    emergencyContacts.value = [
      EmergencyContactModel(
        id: '1',
        name: 'Jane Doe',
        relation: 'Spouse',
        phoneNumber: '+1 234 567 8901',
        isPrimary: true,
      ),
      EmergencyContactModel(
        id: '2',
        name: 'Dr. Michael Chen',
        relation: 'Physician',
        phoneNumber: '+1 987 654 3210',
      ),
    ];
  }

  void addContact(EmergencyContactModel contact) {
    emergencyContacts.add(contact);
  }

  void removeContact(String id) {
    emergencyContacts.removeWhere((c) => c.id == id);
  }
}
