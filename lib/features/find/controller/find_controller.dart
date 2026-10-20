import 'package:get/get.dart';
import '../model/doctor_model.dart';
import '../model/hospital_model.dart';

class FindController extends GetxController {
  var doctors = <DoctorModel>[].obs;
  var hospitals = <HospitalModel>[].obs;
  var filteredDoctors = <DoctorModel>[].obs;
  var filteredHospitals = <HospitalModel>[].obs;

  var searchQuery = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
    
    debounce(searchQuery, (_) => _applyFilter(), time: const Duration(milliseconds: 300));
  }

  void _loadDummyData() {
    doctors.value = [
      DoctorModel(
        id: '1',
        name: 'Dr. Samantha Smith',
        specialty: 'Cardiologist',
        experience: '10 yrs exp',
        rating: 4.8,
        imageUrl: 'https://img.freepik.com/free-photo/pleased-young-female-doctor-wearing-medical-robe-with-stethoscope-around-neck-standing-with-folded-arms-isolated-olive-green-background_141793-105551.jpg',
        about: 'Expert in heart-related ailments with over 10 years of experience in clinical practice.',
      ),
      DoctorModel(
        id: '2',
        name: 'Dr. Michael Chen',
        specialty: 'Neurologist',
        experience: '8 yrs exp',
        rating: 4.9,
        imageUrl: 'https://img.freepik.com/free-photo/doctor-with-his-arms-crossed-white-background_1368-5790.jpg',
        about: 'Specializes in brain and nervous system disorders, focus on migraine management.',
      ),
      DoctorModel(
        id: '3',
        name: 'Dr. Emily Brown',
        specialty: 'Pediatrician',
        experience: '12 yrs exp',
        rating: 4.7,
        imageUrl: 'https://img.freepik.com/free-photo/woman-doctor-wearing-lab-coat-with-stethoscope-isolated_1303-29791.jpg',
        about: 'Compassionate care for children and adolescents, focusing on preventive medicine.',
      ),
    ];

    hospitals.value = [
      HospitalModel(
        id: '1',
        name: 'City General Hospital',
        address: '123 Health Ave, New York',
        rating: 4.5,
        imageUrl: 'https://img.freepik.com/free-photo/modern-hospital-building_1127-3132.jpg',
        services: ['Emergency', 'Surgery', 'Pediatrics'],
      ),
      HospitalModel(
        id: '2',
        name: 'Wellness Medical Center',
        address: '456 Wellness Blvd, Brooklyn',
        rating: 4.2,
        imageUrl: 'https://img.freepik.com/free-photo/blurred-interior-hospital-corridor-with-light-from-windows_1127-4406.jpg',
        services: ['Diagnostics', 'Physiotherapy', 'Dental'],
      ),
    ];

    filteredDoctors.assignAll(doctors);
    filteredHospitals.assignAll(hospitals);
  }

  void _applyFilter() {
    if (searchQuery.isEmpty) {
      filteredDoctors.assignAll(doctors);
      filteredHospitals.assignAll(hospitals);
    } else {
      filteredDoctors.assignAll(doctors.where((d) =>
          d.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          d.specialty.toLowerCase().contains(searchQuery.value.toLowerCase())));
      
      filteredHospitals.assignAll(hospitals.where((h) =>
          h.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          h.address.toLowerCase().contains(searchQuery.value.toLowerCase())));
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }
}
