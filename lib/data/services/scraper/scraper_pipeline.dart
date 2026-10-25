import 'dart:async';
import 'package:flutter/foundation.dart';
import '../supabase_service.dart';
import 'bookmyshow_scraper.dart';
import 'ticketkhidkee_scraper.dart';
import 'ticketalay_scraper.dart';

class ScraperRunLog {
  final DateTime timestamp;
  final String level; // INFO, SUCCESS, ERROR, WARN
  final String message;

  ScraperRunLog({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}

class ScraperPipeline {
  static final ScraperPipeline _instance = ScraperPipeline._internal();
  factory ScraperPipeline() => _instance;
  ScraperPipeline._internal();

  final BookMyShowScraper _bms = BookMyShowScraper();
  final TicketKhidkeeScraper _khidkee = TicketKhidkeeScraper();
  final TicketAlayScraper _alay = TicketAlayScraper();

  final StreamController<ScraperRunLog> _logController =
      StreamController<ScraperRunLog>.broadcast();

  Stream<ScraperRunLog> get logStream => _logController.stream;
  bool isRunning = false;

  void _log(String level, String message) {
    debugPrint('[$level] $message');
    _logController.add(
      ScraperRunLog(timestamp: DateTime.now(), level: level, message: message),
    );
  }

  /// Run all scrapers or a specific target
  Future<int> runPipeline({
    String target = 'all',
    String region = 'Pune',
  }) async {
    if (isRunning) {
      _log('WARN', 'Pipeline is already running in background.');
      return 0;
    }

    isRunning = true;
    int ingestedCount = 0;

    _log('INFO', '=== Starting REA Scraper Pipeline (Target: $target, Region: $region) ===');

    try {
      List<Map<String, dynamic>> extractedEvents = [];

      // 1. BookMyShow Scraper
      if (target == 'all' || target == 'bms') {
        _log('INFO', '[REA] Executing BookMyShow reverse-engineered engine...');
        final bmsItems = await _bms.scrapeCatalog(region: region);
        _log('SUCCESS', '[REA] BookMyShow extracted ${bmsItems.length} show records.');
        extractedEvents.addAll(bmsItems);
      }

      // 2. TicketKhidkee Scraper
      if (target == 'all' || target == 'khidkee') {
        _log('INFO', '[REA] Executing TicketKhidkee Marathi theatre engine...');
        final khidkeeItems = await _khidkee.scrapeCatalog(region: region);
        _log('SUCCESS', '[REA] TicketKhidkee extracted ${khidkeeItems.length} Natak records.');
        extractedEvents.addAll(khidkeeItems);
      }

      // 3. TicketAlay Scraper
      if (target == 'all' || target == 'alay') {
        _log('INFO', '[REA] Executing TicketAlay cultural portal engine...');
        final alayItems = await _alay.scrapeCatalog(region: region);
        _log('SUCCESS', '[REA] TicketAlay extracted ${alayItems.length} cultural records.');
        extractedEvents.addAll(alayItems);
      }

      _log('INFO', 'Normalizing and syncing ${extractedEvents.length} items to Supabase database...');

      // Ingest to Supabase
      final supabase = SupabaseService().client;

      for (var item in extractedEvents) {
        try {
          final slug = item['slug'] ?? 'show-${DateTime.now().millisecondsSinceEpoch}';

          // Check if event already exists
          final existing = await supabase.from('events').select('id').eq('slug', slug);

          int eventId;
          if ((existing as List).isNotEmpty) {
            eventId = existing.first['id'];
            _log('INFO', 'Event "$slug" already exists (ID: $eventId). Updating showtimes...');
          } else {
            // Insert event
            final insertRes = await supabase.from('events').insert({
              'organizer_id': 1,
              'venue_id': 1,
              'title': item['title'],
              'title_mr': item['title_mr'],
              'slug': slug,
              'category': item['category'],
              'category_mr': item['category_mr'],
              'language': item['language'] ?? 'Marathi',
              'age_guidance': item['age_guidance'] ?? 'U',
              'duration_minutes': item['duration_minutes'] ?? 150,
              'description': item['description'] ?? '',
              'description_mr': item['description_mr'] ?? '',
              'poster_url': item['poster_url'],
              'banner_url': item['banner_url'],
              'featured': item['featured'] ?? 0,
              'tag': item['tag'],
              'status': 'published',
            }).select('id').single();

            eventId = insertRes['id'];
            ingestedCount++;
            _log('SUCCESS', 'Created new event: "${item['title']}" (ID: $eventId)');
          }

          // Sessions
          if (item['sessions'] is List) {
            for (var sess in item['sessions']) {
              final startTime = sess['start_time'];
              final endTime = sess['end_time'];

              // Check existing session
              final existingSession = await supabase
                  .from('event_sessions')
                  .select('id')
                  .eq('event_id', eventId)
                  .eq('session_start_time', startTime);

              if ((existingSession as List).isEmpty) {
                final newSess = await supabase.from('event_sessions').insert({
                  'event_id': eventId,
                  'session_start_time': startTime,
                  'session_end_time': endTime,
                  'status': 'active',
                }).select('id').single();

                final sessionId = newSess['id'];

                // Insert pricing ticket tiers
                if (item['price_tiers'] is List) {
                  for (var pt in item['price_tiers']) {
                    await supabase.from('ticket_types').insert({
                      'event_id': eventId,
                      'session_id': sessionId,
                      'name': pt['name'],
                      'name_mr': pt['name_mr'],
                      'price': (pt['price_rupees'] as int) * 100, // into paise
                      'total_quota': 150,
                      'available_quota': 140,
                      'is_seated': 1,
                    });
                  }
                }
                _log('SUCCESS', 'Scheduled showtime session ID: $sessionId for Event ID: $eventId');
              }
            }
          }
        } catch (itemErr) {
          _log('ERROR', 'Error ingesting "${item['title']}": $itemErr');
        }
      }

      _log('SUCCESS', '=== Pipeline Completed! Successfully processed ${extractedEvents.length} events ($ingestedCount newly created) ===');
    } catch (e) {
      _log('ERROR', 'Pipeline execution failed: $e');
    } finally {
      isRunning = false;
    }

    return ingestedCount;
  }
}
