class EmergencyContactModel {
  final String id;
  final String name;
  final String relation;
  final String phoneNumber;
  final bool isPrimary;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.phoneNumber,
    this.isPrimary = false,
  });
}
