import 'package:dio/dio.dart';

import '../../core/Util/maps_config.dart';

class PlacesException implements Exception {
  PlacesException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Google Places Nearby / Text Search / Details (HTTP). Not Healora APIs.
class PlacesService {
  PlacesService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  final Dio _dio;
  static const _base = 'https://maps.googleapis.com/maps/api/place';

  static String photoUrl(String photoReference, {int maxWidth = 800}) {
    return '$_base/photo?maxwidth=$maxWidth'
        '&photo_reference=${Uri.encodeQueryComponent(photoReference)}'
        '&key=${MapsConfig.apiKey}';
  }

  Future<List<Map<String, dynamic>>> nearby({
    required double lat,
    required double lng,
    required String type,
    String keyword = '',
    int radiusMeters = 8000,
  }) {
    final params = <String, dynamic>{
      'location': '$lat,$lng',
      'radius': '$radiusMeters',
      'type': type,
      'key': MapsConfig.apiKey,
    };
    if (keyword.trim().isNotEmpty) {
      params['keyword'] = keyword.trim();
    }
    return _results('$_base/nearbysearch/json', params);
  }

  Future<List<Map<String, dynamic>>> textSearch({
    required String query,
    String? type,
  }) {
    final params = <String, dynamic>{
      'query': query,
      'key': MapsConfig.apiKey,
    };
    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }
    return _results('$_base/textsearch/json', params);
  }

  Future<Map<String, dynamic>?> details(String placeId) async {
    final res = await _dio.get(
      '$_base/details/json',
      queryParameters: {
        'place_id': placeId,
        'fields':
            'place_id,name,formatted_address,vicinity,formatted_phone_number,'
                'international_phone_number,website,geometry,rating,'
                'user_ratings_total,opening_hours,photos,reviews,url,types,'
                'editorial_summary,business_status',
        'key': MapsConfig.apiKey,
      },
    );
    final data = res.data;
    if (data is! Map) return null;
    _throwIfDenied(data);
    if (data['status']?.toString() != 'OK') return null;
    final result = data['result'];
    if (result is Map<String, dynamic>) return result;
    if (result is Map) return Map<String, dynamic>.from(result);
    return null;
  }

  Future<List<Map<String, dynamic>>> _results(
    String url,
    Map<String, dynamic> params,
  ) async {
    final res = await _dio.get(url, queryParameters: params);
    final data = res.data;
    if (data is! Map) return [];
    _throwIfDenied(data);
    final status = data['status']?.toString() ?? '';
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw PlacesException(
        data['error_message']?.toString() ?? 'Places lookup failed ($status)',
      );
    }
    final results = data['results'];
    if (results is! List) return [];
    return results
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _throwIfDenied(Map data) {
    final status = data['status']?.toString() ?? '';
    if (status == 'REQUEST_DENIED' || status == 'OVER_QUERY_LIMIT') {
      throw PlacesException(
        data['error_message']?.toString() ??
            'Google Places is not enabled for this Maps key ($status).',
      );
    }
  }
}
