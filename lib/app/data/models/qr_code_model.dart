class QrCodeResponse {
  final bool error;
  final int errorCode;
  final String message;
  final QrCodeData? data;

  QrCodeResponse({
    required this.error,
    required this.errorCode,
    required this.message,
    this.data,
  });

  factory QrCodeResponse.fromJson(Map<String, dynamic> json) {
    return QrCodeResponse(
      error: json['error'] == true,
      errorCode: json['error_code'] is int
          ? json['error_code']
          : int.tryParse('${json['error_code']}') ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map
          ? QrCodeData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class QrCodeData {
  final QrInfo? qr;
  final QrToken? token;
  final String? jwt;
  final String? patientId;
  final bool regenerated;
  final QrOptions? options;
  final String? lastScannedAt;

  QrCodeData({
    this.qr,
    this.token,
    this.jwt,
    this.patientId,
    this.regenerated = false,
    this.options,
    this.lastScannedAt,
  });

  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      qr: json['qr'] is Map
          ? QrInfo.fromJson(Map<String, dynamic>.from(json['qr']))
          : null,
      token: json['token'] is Map
          ? QrToken.fromJson(Map<String, dynamic>.from(json['token']))
          : null,
      jwt: json['jwt']?.toString(),
      patientId: json['patient'] is Map
          ? json['patient']['patient_id']?.toString()
          : json['patient_id']?.toString(),
      regenerated: json['regenerated'] == true,
      options: json['options'] is Map
          ? QrOptions.fromJson(Map<String, dynamic>.from(json['options']))
          : null,
      lastScannedAt: json['last_scanned_at']?.toString() ??
          json['last_scanned']?.toString(),
    );
  }
}

class QrInfo {
  final String? uuid;
  final String? displayId;
  final String? status;
  final String? imageUrl;
  final String? imageSvgUrl;
  final String? scanUrl;
  final String? payloadUrl;
  final DateTime? expiresAt;
  final int expiryMinutes;
  final bool isCurrent;
  final int version;
  final List<String> capabilities;

  QrInfo({
    this.uuid,
    this.displayId,
    this.status,
    this.imageUrl,
    this.imageSvgUrl,
    this.scanUrl,
    this.payloadUrl,
    this.expiresAt,
    this.expiryMinutes = 10,
    this.isCurrent = true,
    this.version = 1,
    this.capabilities = const [],
  });

  factory QrInfo.fromJson(Map<String, dynamic> json) {
    return QrInfo(
      uuid: json['uuid']?.toString(),
      displayId: json['display_id']?.toString(),
      status: json['status']?.toString(),
      imageUrl: json['image_url']?.toString(),
      imageSvgUrl: json['image_svg_url']?.toString(),
      scanUrl: json['scan_url']?.toString(),
      payloadUrl: json['payload_url']?.toString(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      expiryMinutes: json['expiry_minutes'] is int
          ? json['expiry_minutes']
          : int.tryParse('${json['expiry_minutes']}') ?? 10,
      isCurrent: json['is_current'] != false,
      version: json['version'] is int
          ? json['version']
          : int.tryParse('${json['version']}') ?? 1,
      capabilities: json['capabilities'] is List
          ? (json['capabilities'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  /// Resolve localhost media URLs to production host.
  String? get resolvedImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    var url = imageUrl!;
    if (url.contains('localhost') || url.contains('127.0.0.1')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        url = 'https://medconnect.airainnovations.com${uri.path}';
        if (uri.hasQuery) url = '$url?${uri.query}';
      }
    }
    return url;
  }
}

class QrToken {
  final String? uuid;
  final String? displayId;
  final String? status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? viewUrl;

  QrToken({
    this.uuid,
    this.displayId,
    this.status,
    this.issuedAt,
    this.expiresAt,
    this.viewUrl,
  });

  factory QrToken.fromJson(Map<String, dynamic> json) {
    return QrToken(
      uuid: json['uuid']?.toString(),
      displayId: json['display_id']?.toString(),
      status: json['status']?.toString(),
      issuedAt: DateTime.tryParse(json['issued_at']?.toString() ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      viewUrl: json['view_url']?.toString(),
    );
  }
}

class QrOptions {
  final List<int> allowedExpiryMinutes;
  final int defaultExpiryMinutes;
  final int rateLimitPerHour;

  QrOptions({
    this.allowedExpiryMinutes = const [5, 10, 15, 30],
    this.defaultExpiryMinutes = 10,
    this.rateLimitPerHour = 10,
  });

  factory QrOptions.fromJson(Map<String, dynamic> json) {
    List<int> allowed = const [5, 10, 15, 30];
    if (json['allowed_expiry_minutes'] is List) {
      allowed = (json['allowed_expiry_minutes'] as List)
          .map((e) => int.tryParse('$e') ?? 0)
          .where((e) => e > 0)
          .toList();
    }
    return QrOptions(
      allowedExpiryMinutes: allowed.isEmpty ? const [5, 10, 15, 30] : allowed,
      defaultExpiryMinutes: json['default_expiry_minutes'] is int
          ? json['default_expiry_minutes']
          : int.tryParse('${json['default_expiry_minutes']}') ?? 10,
      rateLimitPerHour: json['rate_limit_per_hour'] is int
          ? json['rate_limit_per_hour']
          : int.tryParse('${json['rate_limit_per_hour']}') ?? 10,
    );
  }
}
