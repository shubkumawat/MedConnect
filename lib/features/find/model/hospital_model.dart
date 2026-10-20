class HospitalModel {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String imageUrl;
  final List<String> services;

  HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.imageUrl,
    required this.services,
  });
}
