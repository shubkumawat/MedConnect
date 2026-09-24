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

bool get isIndia {
  final n = name.trim().toLowerCase();
  final code = phoneCode.replaceAll(RegExp(r'[^0-9]'), '');
  return n == 'india' ||
      iso2.trim().toUpperCase() == 'IN' ||
      iso3.trim().toUpperCase() == 'IND' ||
      code == '91';
}

static CountryModel get indiaFallback => CountryModel(
      id: 0,
      countryId: '',
      name: 'India',
      iso2: 'IN',
      iso3: 'IND',
      phoneCode: '91',
      flagEmoji: '🇮🇳',
    );

static CountryModel indiaFrom(Iterable<CountryModel> list) {
  for (final c in list) {
    if (c.isIndia) return c;
  }
  return indiaFallback;
}

/// Master APIs return `{ countries: [...] }` (or `{ relations: [...] }`),
/// never a bare list. Using `data as List` throws on Personal Info.
static List<dynamic> namedList(dynamic data, String key) {
  if (data is List) return data;
  if (data is Map) {
    final nested = data[key];
    if (nested is List) return nested;
    if (nested is Map) {
      final results = nested['results'];
      if (results is List) return results;
      final again = nested[key];
      if (again is List) return again;
    }
  }
  return const [];
}
}