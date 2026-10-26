import 'package:flutter/foundation.dart';
import '../data/models/event_model.dart';
import '../data/models/home_section_model.dart';
import '../data/services/supabase_service.dart';

class EventsProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  String _selectedCity = 'Pune';
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  List<HomeSectionModel> _homeSections = [];
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _venues = [];

  String get selectedCity => _selectedCity;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  List<EventModel> get events => _filteredEvents;
  List<EventModel> get allEvents => _allEvents;
  List<EventModel> get featuredEvents =>
      _allEvents.where((e) => e.featured == 1).toList();
  List<HomeSectionModel> get homeSections => _homeSections;
  List<Map<String, dynamic>> get announcements => _announcements;
  List<Map<String, dynamic>> get venues => _venues;

  final List<String> availableCities = [
    'Pune',
    'Mumbai',
    'Nashik',
    'Nagpur',
    'Kolhapur',
    'Chhatrapati Sambhajinagar',
    'Thane',
  ];

  final List<Map<String, String>> categories = [
    {'id': 'all', 'label': 'All Shows', 'labelMr': 'सर्व प्रयोग'},
    {'id': 'plays', 'label': 'Plays / Natak', 'labelMr': 'नाटके'},
    {'id': 'movies', 'label': 'Movies', 'labelMr': 'चित्रपट'},
    {'id': 'music', 'label': 'Concerts', 'labelMr': 'संगीत'},
    {'id': 'cultural', 'label': 'Cultural', 'labelMr': 'महोत्सव'},
    {'id': 'comedy', 'label': 'Standup', 'labelMr': 'हास्य प्रयोग'},
  ];

  static const List<HomeSectionModel> _defaultSections = [
    HomeSectionModel(id: 0, sectionKey: 'hero', titleEn: 'Featured Shows', titleMr: 'विशेष आकर्षण', sortOrder: 1),
    HomeSectionModel(id: 0, sectionKey: 'trending', titleEn: 'Top Trending', titleMr: 'ट्रेंडिंग प्रयोग', sortOrder: 2),
    HomeSectionModel(id: 0, sectionKey: 'categories', titleEn: 'Categories', titleMr: 'श्रेणी', sortOrder: 3),
    HomeSectionModel(id: 0, sectionKey: 'today', titleEn: "What's On Today", titleMr: 'आज काय पाहायचं?', sortOrder: 4),
    HomeSectionModel(id: 0, sectionKey: 'promoted', titleEn: 'Promoted', titleMr: 'प्रमोटेड शो', sortOrder: 5),
    HomeSectionModel(id: 0, sectionKey: 'drama', titleEn: 'Marathi Theatre', titleMr: 'मराठी नाटके', sortOrder: 6),
    HomeSectionModel(id: 0, sectionKey: 'music', titleEn: 'Music & Live', titleMr: 'संगीत व लाइव्ह', sortOrder: 7),
    HomeSectionModel(id: 0, sectionKey: 'venues', titleEn: 'Iconic Theatres', titleMr: 'प्रसिद्ध नाट्यगृहे', sortOrder: 8),
  ];

  EventsProvider() {
    loadHome();
  }

  HomeSectionModel? sectionByKey(String key) {
    try {
      return _homeSections.firstWhere((s) => s.sectionKey == key && s.isVisible);
    } catch (_) {
      return null;
    }
  }

  bool isSectionVisible(String key) {
    if (_homeSections.isEmpty) return true;
    final match = _homeSections.where((s) => s.sectionKey == key);
    if (match.isEmpty) return key == 'categories' || key == 'hero';
    return match.first.isVisible;
  }

  String sectionTitle(
    String key,
    String fallbackEn,
    String fallbackMr, {
    required bool marathi,
  }) {
    final s = sectionByKey(key);
    if (s == null) {
      return marathi
          ? (fallbackMr.trim().isNotEmpty ? fallbackMr : fallbackEn)
          : (fallbackEn.trim().isNotEmpty ? fallbackEn : fallbackMr);
    }
    return s.localizedTitle(marathi: marathi);
  }

  void setCity(String city) {
    if (_selectedCity != city) {
      _selectedCity = city;
      notifyListeners();
      loadHome();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  Future<void> loadEvents() => loadHome();

  Future<void> loadHome() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _supabaseService.getEvents(city: _selectedCity),
        _supabaseService.getHomeSections(visibleOnly: false),
        _supabaseService.getActiveAnnouncements(city: _selectedCity),
        _supabaseService.getPublishedVenues(city: _selectedCity),
      ]);

      _allEvents = results[0] as List<EventModel>;
      final sections = results[1] as List<HomeSectionModel>;
      if (sections.isNotEmpty) {
        _homeSections = sections.where((s) => s.isVisible).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      } else {
        _homeSections = List<HomeSectionModel>.from(_defaultSections);
      }
      _announcements = results[2] as List<Map<String, dynamic>>;
      _venues = results[3] as List<Map<String, dynamic>>;
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading home in provider: $e');
      if (_homeSections.isEmpty) _homeSections = _defaultSections;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<EventModel> eventsForSection(String key) {
    switch (key) {
      case 'hero':
      case 'promoted':
        final featured = featuredEvents;
        return featured.isNotEmpty ? featured : _allEvents.take(6).toList();
      case 'trending':
      case 'today':
        return _allEvents.take(8).toList();
      case 'drama':
        return _allEvents
            .where((e) => e.category.toLowerCase() == 'plays')
            .take(12)
            .toList();
      case 'music':
        return _allEvents
            .where((e) {
              final c = e.category.toLowerCase();
              return c == 'music' || c == 'festivals' || c == 'cultural';
            })
            .take(12)
            .toList();
      default:
        return _filteredEvents;
    }
  }

  void _applyFilters() {
    _filteredEvents = _allEvents.where((event) {
      final matchesCategory = _selectedCategory == 'all' ||
          event.category.toLowerCase() == _selectedCategory.toLowerCase();

      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          event.title.toLowerCase().contains(q) ||
          event.titleMr.toLowerCase().contains(q) ||
          event.category.toLowerCase().contains(q) ||
          event.description.toLowerCase().contains(q) ||
          event.venueDisplayName.toLowerCase().contains(q);

      final matchesCity = _selectedCity.isEmpty ||
          event.venueCity.toLowerCase().contains(_selectedCity.toLowerCase()) ||
          event.venue == null;

      return matchesCategory && matchesSearch && matchesCity;
    }).toList();
  }
}
