import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/event_model.dart';
import '../data/models/venue_model.dart';
import '../data/models/session_model.dart';
import '../data/models/seat_model.dart';
import '../data/services/supabase_service.dart';
import '../data/services/inventory_service.dart';

class BookingProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final InventoryService _inventoryService = InventoryService();

  EventModel? _selectedEvent;
  VenueModel? _selectedVenue;
  SessionModel? _selectedSession;
  List<SessionModel> _sessions = [];
  List<TicketTypeModel> _ticketTypes = [];
  List<SeatModel> _venueSeats = [];
  List<VenueSectionModel> _venueSections = [];
  List<SeatInventoryModel> _inventory = [];

  final List<SeatModel> _selectedSeats = [];
  String _holdToken = '';
  HoldResult? _holdResult;
  String? _couponCode;
  String? _conflictError;

  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _isLoading = false;
  RealtimeChannel? _realtimeSubscription;

  // Getters
  EventModel? get selectedEvent => _selectedEvent;
  VenueModel? get selectedVenue => _selectedVenue;
  SessionModel? get selectedSession => _selectedSession;
  List<SessionModel> get sessions => _sessions;
  List<TicketTypeModel> get ticketTypes => _ticketTypes;
  List<SeatModel> get venueSeats => _venueSeats;
  List<VenueSectionModel> get venueSections => _venueSections;
  List<SeatInventoryModel> get inventory => _inventory;
  List<SeatModel> get selectedSeats => _selectedSeats;
  String get holdToken => _holdToken;
  HoldResult? get holdResult => _holdResult;
  String? get couponCode => _couponCode;
  String? get conflictError => _conflictError;
  int get secondsLeft => _secondsLeft;
  bool get isLoading => _isLoading;
  bool get hasActiveHold => _secondsLeft > 0 && _holdResult != null && _holdResult!.success;

  String get formattedTimeLeft {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> initEvent(EventModel event) async {
    _selectedEvent = event;
    _selectedSession = null;
    _selectedSeats.clear();
    _holdToken = _inventoryService.createHoldToken();
    _cancelTimer();
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    _sessions = await _supabaseService.getEventSessions(event.id);
    _selectedVenue = await _supabaseService.getVenueById(event.venueId);

    if (_sessions.isNotEmpty) {
      await selectSession(_sessions.first);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectSession(SessionModel session) async {
    _selectedSession = session;
    _selectedSeats.clear();
    _conflictError = null;
    _cancelTimer();
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    // Cleanup previous subscription
    _realtimeSubscription?.unsubscribe();

    // 1. Fetch ticket types & seats
    _ticketTypes = await _supabaseService.getTicketTypes(session.id);
    if (_selectedEvent != null) {
      _venueSeats = await _supabaseService.getVenueSeats(_selectedEvent!.venueId);
      _venueSections = await _supabaseService.getVenueSections(_selectedEvent!.venueId);
    }

    // 2. Fetch initial seat inventory
    await _refreshInventory();

    // 3. Setup real-time listener for live seat lock updates
    _realtimeSubscription = _inventoryService.subscribeToSessionSeats(
      sessionId: session.id,
      onUpdate: (updatedInventory) {
        _inventory = updatedInventory;
        notifyListeners();
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshInventory() async {
    if (_selectedSession == null) return;
    _inventory = await _supabaseService.getSeatInventory(_selectedSession!.id);
    notifyListeners();
  }

  /// Toggle selection of a physical seat
  Future<bool> toggleSeat(SeatModel seat) async {
    if (_selectedSession == null) return false;
    _conflictError = null;

    final isAlreadySelected = _selectedSeats.any((s) => s.id == seat.id);

    if (isAlreadySelected) {
      _selectedSeats.removeWhere((s) => s.id == seat.id);
      // Release individual seat hold
      await _inventoryService.releaseUserHold(
        sessionId: _selectedSession!.id,
        holdToken: _holdToken,
        seatIds: [seat.id],
      );

      if (_selectedSeats.isEmpty) {
        _cancelTimer();
      } else {
        await _applySeatHold();
      }
      notifyListeners();
      return true;
    }

    // Max 5 seats limit (BookMyShow / TicketGhar rule)
    if (_selectedSeats.length >= 5) {
      _conflictError = 'max_seats';
      notifyListeners();
      return false;
    }

    // Check if seat is booked or held by someone else
    final inv = _inventory.firstWhere(
      (i) => i.seatId == seat.id,
      orElse: () => SeatInventoryModel(
        id: 0,
        sessionId: _selectedSession!.id,
        seatId: seat.id,
        ticketTypeId: _ticketTypes.isNotEmpty ? _ticketTypes.first.id : 1,
        status: 'available',
      ),
    );

    if (!inv.isAvailableForUser(_holdToken)) {
      _conflictError = 'seat_held:${seat.seatCode}';
      notifyListeners();
      return false;
    }

    _selectedSeats.add(seat);
    notifyListeners();

    // Lock seats atomically
    return await _applySeatHold();
  }

  /// Apply 5-minute seat reservation
  Future<bool> _applySeatHold() async {
    if (_selectedSession == null || _selectedSeats.isEmpty) return false;

    final seatIds = _selectedSeats.map((s) => s.id).toList();
    final result = await _inventoryService.holdSeats(
      sessionId: _selectedSession!.id,
      seatIds: seatIds,
      holdToken: _holdToken,
      couponCode: _couponCode,
    );

    _holdResult = result;

    if (!result.success) {
      final raw = (result.errorMessage ?? '').toLowerCase();
      if (raw.contains('held') ||
          raw.contains('another') ||
          raw.contains('no longer available') ||
          raw.contains('not available')) {
        _conflictError = 'seat_conflict';
      } else if (raw.contains('maximum') || raw.contains('max')) {
        _conflictError = 'max_seats';
      } else {
        _conflictError = result.errorMessage ?? 'hold_failed';
      }
      // remove conflicting seats and refresh map for live availability
      _selectedSeats.clear();
      _cancelTimer();
      await _refreshInventory();
      notifyListeners();
      return false;
    }

    // Start 5-minute countdown timer
    _startTimer(result.expiresAt);
    await _refreshInventory();
    notifyListeners();
    return true;
  }

  void _startTimer(DateTime? expiresAt) {
    _cancelTimer();
    final duration = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inSeconds
        : 300;
    _secondsLeft = duration.clamp(0, 300);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsLeft <= 1) {
        _secondsLeft = 0;
        _cancelTimer();
        // Release expired seats
        if (_selectedSession != null) {
          await _inventoryService.releaseUserHold(
            sessionId: _selectedSession!.id,
            holdToken: _holdToken,
          );
        }
        _selectedSeats.clear();
        _conflictError = 'hold_expired';
        notifyListeners();
      } else {
        _secondsLeft--;
        notifyListeners();
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _secondsLeft = 0;
  }

  void applyCoupon(String code) {
    _couponCode = code.trim();
    if (_selectedSeats.isNotEmpty) {
      _applySeatHold();
    }
  }

  void removeCoupon() {
    _couponCode = null;
    if (_selectedSeats.isNotEmpty) {
      _applySeatHold();
    }
  }

  Future<void> releaseHold() async {
    if (_selectedSession != null && _holdToken.isNotEmpty) {
      await _inventoryService.releaseUserHold(
        sessionId: _selectedSession!.id,
        holdToken: _holdToken,
      );
    }
    _cancelTimer();
    _selectedSeats.clear();
    _holdResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    _cancelTimer();
    super.dispose();
  }
}
