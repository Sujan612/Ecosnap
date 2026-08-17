import 'dart:convert';
import 'package:http/http.dart' as http;

/// Single shared Unsplash lookup used across the app (home carousel, recent
/// discoveries, recognition results, species details). Do not duplicate this
/// HTTP call elsewhere — reuse this service so requests are cached and
/// consistent.
class UnsplashService {
  static const String _accessKey =
      'L9O7YV1ylnJQMNsw7ixuEDcDj0GF7j_EYilxYS6G3I0';

  // Simple in-memory cache shared by all instances/screens for the lifetime
  // of the app. Prevents re-hitting the Unsplash API for the same keyword
  // every time a widget rebuilds (e.g. on scroll or navigation).
  static final Map<String, Future<String?>> _cache = {};

  Future<String?> _fetch(String query) async {
    final url = Uri.parse(
      'https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(query)}&per_page=1&client_id=$_accessKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];
        if (results != null && (results as List).isNotEmpty) {
          return results[0]['urls']['regular'] as String?;
        }
      }
    } catch (_) {
      // Network error, timeout, etc. Fall through to null so callers can
      // show a placeholder instead of crashing.
    }
    return null;
  }

  /// Fetch (and cache) an image URL for [keyword]. If [fallbackKeyword] is
  /// given and the first query returns nothing, it is tried as a backup
  /// (e.g. "aloe-vera" -> "aloe vera").
  Future<String?> fetchImageUrl(String keyword, {String? fallbackKeyword}) {
    final cacheKey = fallbackKeyword != null
        ? '$keyword|$fallbackKeyword'
        : keyword;

    return _cache.putIfAbsent(cacheKey, () async {
      final primary = await _fetch(keyword);
      if (primary != null) return primary;
      if (fallbackKeyword != null && fallbackKeyword != keyword) {
        return _fetch(fallbackKeyword);
      }
      return null;
    });
  }
}
