class CountryModel {
final int id;
final String countryId;
final String name;
final String iso2;
final String iso3;
final String phoneCode;
final String flagEmoji;

CountryModel({
  required this.id,
  required this.countryId,
  required this.name,
  required this.iso2,
  required this.iso3,
  required this.phoneCode,
  required this.flagEmoji,
});

factory CountryModel.fromJson(Map<String, dynamic> json) {
return CountryModel(
id: json['id'] ?? 0,
countryId: json['country_id']?.toString() ?? '',
name: json['name']?.toString() ?? '',
iso2: json['iso2']?.toString() ?? '',
iso3: json['iso3']?.toString() ?? '',
phoneCode: json['phone_code']?.toString() ?? '',
flagEmoji: json['flag_emoji']?.toString() ?? '',
);
}
}