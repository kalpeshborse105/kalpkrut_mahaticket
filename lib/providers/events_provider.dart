import 'package:flutter/foundation.dart';
import '../data/models/event_model.dart';
import '../data/services/supabase_service.dart';

class EventsProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  String _selectedCity = 'Pune';
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];

  String get selectedCity => _selectedCity;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  List<EventModel> get events => _filteredEvents;
  List<EventModel> get featuredEvents =>
      _allEvents.where((e) => e.featured == 1).toList();

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

  EventsProvider() {
    loadEvents();
  }

  void setCity(String city) {
    if (_selectedCity != city) {
      _selectedCity = city;
      notifyListeners();
      loadEvents();
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

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allEvents = await _supabaseService.getEvents();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading events in provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredEvents = _allEvents.where((event) {
      // Category filter
      final matchesCategory = _selectedCategory == 'all' ||
          event.category.toLowerCase() == _selectedCategory.toLowerCase();

      // Search query filter
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          event.title.toLowerCase().contains(q) ||
          event.titleMr.toLowerCase().contains(q) ||
          event.category.toLowerCase().contains(q) ||
          event.description.toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();
  }
}
