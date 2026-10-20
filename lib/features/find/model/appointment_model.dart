import 'doctor_model.dart';

class AppointmentModel {
  final String id;
  final DoctorModel doctor;
  final DateTime dateTime;
  final String patientId;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String type; // 'Video' or 'In-Person'

  AppointmentModel({
    required this.id,
    required this.doctor,
    required this.dateTime,
    required this.patientId,
    this.status = 'pending',
    required this.type,
  });
}
