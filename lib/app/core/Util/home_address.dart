/// API `home_address` may be a Map or a legacy comma-separated string.
class HomeAddress {
  final String address;
  final String city;
  final String state;
  final String postCode;

  const HomeAddress({
    this.address = '',
    this.city = '',
    this.state = '',
    this.postCode = '',
  });

  bool get isEmpty =>
      address.trim().isEmpty &&
      city.trim().isEmpty &&
      state.trim().isEmpty &&
      postCode.trim().isEmpty;

  /// Human-readable line for cards / PDF / update-emergency API string field.
  String get display {
    final parts = <String>[
      if (address.trim().isNotEmpty) address.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (state.trim().isNotEmpty) state.trim(),
      if (postCode.trim().isNotEmpty) postCode.trim(),
    ];
    return parts.join(', ');
  }

  /// Same as [display] — API `home_address` must be a string, not a Map.
  String toApiString() => display;

  Map<String, dynamic> toApiJson() {
    final code = postCode.trim();
    final parsed = int.tryParse(code);
    return {
      'address': address.trim(),
      'city': city.trim(),
      'post_code': parsed ?? code,
      'state': state.trim(),
    };
  }

  static HomeAddress parse(dynamic raw) {
    if (raw == null) return const HomeAddress();

    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return HomeAddress(
        address: m['address']?.toString() ?? m['line']?.toString() ?? '',
        city: m['city']?.toString() ?? '',
        state: m['state']?.toString() ?? '',
        postCode: m['post_code']?.toString() ??
            m['pincode']?.toString() ??
            m['pin_code']?.toString() ??
            '',
      );
    }

    final text = raw.toString().trim();
    if (text.isEmpty || text == 'null') return const HomeAddress();

    // Legacy "City, State" (or longer comma lists).
    final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return const HomeAddress();
    if (parts.length == 1) return HomeAddress(city: parts[0]);
    if (parts.length == 2) {
      return HomeAddress(city: parts[0], state: parts[1]);
    }
    // address, city, state[, post_code]
    return HomeAddress(
      address: parts.first,
      city: parts.length > 1 ? parts[1] : '',
      state: parts.length > 2 ? parts[2] : '',
      postCode: parts.length > 3 ? parts[3] : '',
    );
  }
}
