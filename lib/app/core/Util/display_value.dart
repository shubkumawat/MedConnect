/// Shared empty / placeholder display — always show NA instead of Unknown / dashes.
String displayOrNa(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty ||
      v.toLowerCase() == 'unknown' ||
      v.toLowerCase() == 'null' ||
      v == '--' ||
      v == '—' ||
      v == '-') {
    return 'NA';
  }
  return v;
}

bool isBlankOrUnknown(String? value) {
  final v = (value ?? '').trim().toLowerCase();
  return v.isEmpty ||
      v == 'unknown' ||
      v == 'null' ||
      v == '--' ||
      v == '—' ||
      v == '-';
}
