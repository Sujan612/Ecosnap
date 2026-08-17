import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// One result from Pl@ntNet, already in the shape ResultScreen expects
/// ({'label': ..., 'confidence': ...}) via [toRecognition].
class PlantNetMatch {
  final String scientificName;
  final String? commonName;
  final double confidence;

  PlantNetMatch({
    required this.scientificName,
    required this.commonName,
    required this.confidence,
  });

  /// Prefer the common name (matches the style of the local model's labels
  /// and reads better in the UI); fall back to scientific name.
  Map<String, dynamic> toRecognition() => {
        'label': (commonName ?? scientificName).toLowerCase(),
        'confidence': confidence,
      };
}

/// Minimal Pl@ntNet fallback for plant photos the local TFLite model isn't
/// confident about. Free tier: 500 requests/day, https://my.plantnet.org.
///
/// Requires an API key at build/run time:
///   flutter run --dart-define=PLANTNET_API_KEY=your-key-here
/// If no key is configured, [identify] returns an empty list immediately —
/// the caller then just keeps showing the local model's (low-confidence)
/// result, so this fallback is entirely optional.
class PlantNetService {
  static const String _apiKey = String.fromEnvironment('PLANTNET_API_KEY');
  static const String _endpoint = 'https://my-api.plantnet.org/v2/identify/all';
  static const Duration _timeout = Duration(seconds: 12);

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Returns up to 3 candidate species, best match first. Returns an empty
  /// list (never throws) on missing config, no internet, timeout, rate
  /// limiting, or any other API/parse failure — callers should treat that
  /// as "fallback unavailable, keep the local result".
  Future<List<PlantNetMatch>> identify(File imageFile) async {
    if (!isConfigured) return [];

    try {
      final uri = Uri.parse('$_endpoint?api-key=$_apiKey&lang=en&nb-results=3');
      final request = http.MultipartRequest('POST', uri)
        ..fields['organs'] = 'auto'
        ..files.add(await http.MultipartFile.fromPath('images', imageFile.path));

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      // Rate limited or otherwise unavailable: fall back gracefully.
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final results = (decoded['results'] as List?) ?? [];

      return results.map((r) {
        final species = r['species'] as Map<String, dynamic>;
        final commonNames = (species['commonNames'] as List?) ?? [];
        return PlantNetMatch(
          scientificName: (species['scientificNameWithoutAuthor'] ??
                  species['scientificName'] ??
                  'Unknown')
              .toString(),
          commonName: commonNames.isNotEmpty ? commonNames.first.toString() : null,
          confidence: (r['score'] as num).toDouble(),
        );
      }).toList();
    } on TimeoutException {
      return [];
    } on SocketException {
      return []; // no internet
    } catch (_) {
      return []; // invalid/unexpected response shape
    }
  }
}
