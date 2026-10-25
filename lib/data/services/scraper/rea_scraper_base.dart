import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base REA Scraper following reverse-engineered API evidence contracts
abstract class ReaScraperBase {
  final String sourceName;
  final String baseUrl;

  ReaScraperBase({
    required this.sourceName,
    required this.baseUrl,
  });

  /// Standard headers reverse-engineered from browser & mobile inspection
  Map<String, String> get browserHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
        'Accept':
            'application/json, text/html, application/xhtml+xml, application/xml;q=0.9, image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9,mr;q=0.8,hi;q=0.7',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };

  /// Safe HTTP GET with error handling
  Future<http.Response?> safeGet(String endpoint, {Map<String, String>? extraHeaders}) async {
    try {
      final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
      final headers = {...browserHeaders, ...?extraHeaders};

      debugPrint('[$sourceName REA Scraper] Requesting: $url');
      final response = await http.get(Uri.parse(url), headers: headers).timeout(
            const Duration(seconds: 15),
          );

      debugPrint('[$sourceName REA Scraper] Status: ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[$sourceName REA Scraper] Network error: $e');
      return null;
    }
  }

  /// Extracts events and normalized catalog items
  Future<List<Map<String, dynamic>>> scrapeCatalog({String region = 'Pune'});
}
