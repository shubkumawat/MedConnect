class RiskFactor {
  final String value;
  final String label;

  const RiskFactor({required this.value, required this.label});

  factory RiskFactor.fromJson(Map<String, dynamic> json) {
    final value = (json['value'] ?? json['code'] ?? '').toString().trim();
    final label = (json['label'] ?? json['name'] ?? value).toString().trim();
    return RiskFactor(value: value, label: label.isEmpty ? value : label);
  }

  static List<RiskFactor> listFrom(dynamic raw) {
    if (raw is! List) return [];
    final out = <RiskFactor>[];
    for (final e in raw) {
      if (e is Map) {
        final item = RiskFactor.fromJson(Map<String, dynamic>.from(e));
        if (item.value.isNotEmpty) out.add(item);
      } else {
        final v = e.toString().trim();
        if (v.isNotEmpty) out.add(RiskFactor(value: v, label: v));
      }
    }
    return out;
  }

  static List<String> codesFrom(dynamic raw) {
    return listFrom(raw)
        .map((e) => e.value)
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
