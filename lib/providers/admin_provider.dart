import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/services/supabase_service.dart';
import '../data/services/scraper/scraper_pipeline.dart';

class AdminProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final ScraperPipeline _pipeline = ScraperPipeline();

  Map<String, dynamic> _metrics = {
    'totalRevenueRupees': 0.0,
    'totalTicketsSold': 0,
    'totalEvents': 0,
    'totalScansToday': 0,
  };

  final List<ScraperRunLog> _scraperLogs = [];
  bool _isScraperRunning = false;
  String _selectedScraperTarget = 'all'; // 'all', 'bms', 'khidkee', 'alay'
  StreamSubscription<ScraperRunLog>? _logSub;

  Map<String, dynamic> get metrics => _metrics;
  List<ScraperRunLog> get scraperLogs => List.unmodifiable(_scraperLogs);
  bool get isScraperRunning => _isScraperRunning;
  String get selectedScraperTarget => _selectedScraperTarget;

  AdminProvider() {
    loadMetrics();
    _listenToScraperLogs();
  }

  void _listenToScraperLogs() {
    _logSub = _pipeline.logStream.listen((log) {
      _scraperLogs.add(log);
      notifyListeners();
    });
  }

  void setScraperTarget(String target) {
    _selectedScraperTarget = target;
    notifyListeners();
  }

  Future<void> loadMetrics() async {
    _metrics = await _supabaseService.getAdminMetrics();
    notifyListeners();
  }

  Future<int> runScraper({String region = 'Pune'}) async {
    _isScraperRunning = true;
    _scraperLogs.clear();
    notifyListeners();

    try {
      final count = await _pipeline.runPipeline(
        target: _selectedScraperTarget,
        region: region,
      );
      await loadMetrics();
      return count;
    } finally {
      _isScraperRunning = false;
      notifyListeners();
    }
  }

  void clearLogs() {
    _scraperLogs.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }
}
