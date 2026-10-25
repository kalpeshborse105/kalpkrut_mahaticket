import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';
import '../models/event_model.dart';
import '../models/venue_model.dart';
import '../models/session_model.dart';
import '../models/seat_model.dart';
import '../models/order_model.dart';
import '../models/ticket_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return SupabaseClient(
        EnvConfig.supabaseUrl.isNotEmpty
            ? EnvConfig.supabaseUrl
            : 'https://hnseawulngdxbvltmthe.supabase.co',
        EnvConfig.supabaseAnonKey.isNotEmpty
            ? EnvConfig.supabaseAnonKey
            : 'dummy-anon-key',
      );
    }
  }

  static Future<void> init() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  /// Fetch all active/published events with optional category and city filtering
  Future<List<EventModel>> getEvents({String? category, String? city}) async {
    try {
      final bool hasCity = city != null && city.isNotEmpty && city.toLowerCase() != 'all';
      PostgrestFilterBuilder query = hasCity
          ? client.from('events').select('*, venues!inner(city)')
          : client.from('events').select('*, venues(city)');

      // Respect published lifecycle status
      query = query.eq('status', 'published');

      if (hasCity) {
        query = query.ilike('venues.city', city);
      }

      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        query = query.eq('category', category);
      }

      final response = await query
          .order('featured', ascending: false)
          .order('id', ascending: false);
      return (response as List).map((e) => EventModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  /// Fetch venue sections for layout & tier mapping
  Future<List<VenueSectionModel>> getVenueSections(int venueId) async {
    try {
      final response = await client
          .from('venue_sections')
          .select('*')
          .eq('venue_id', venueId)
          .order('id');
      return (response as List).map((e) => VenueSectionModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching venue sections: $e');
      return [];
    }
  }

  /// Fetch event by ID
  Future<EventModel?> getEventById(int id) async {
    try {
      final response = await client.from('events').select('*').eq('id', id).maybeSingle();
      if (response == null) return null;
      return EventModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting event by id: $e');
      return null;
    }
  }

  /// Fetch venue for an event
  Future<VenueModel?> getVenueById(int venueId) async {
    try {
      final response =
          await client.from('venues').select('*').eq('id', venueId).maybeSingle();
      if (response == null) return null;
      return VenueModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting venue: $e');
      return null;
    }
  }

  /// Fetch venues (all or by city)
  Future<List<VenueModel>> getVenues({String? city}) async {
    try {
      PostgrestFilterBuilder query = client.from('venues').select('*');
      if (city != null && city.isNotEmpty && city.toLowerCase() != 'all') {
        query = query.ilike('city', city);
      }
      final response = await query.order('name');
      return (response as List).map((e) => VenueModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching venues: $e');
      return [];
    }
  }

  /// Alias for getVenues
  Future<List<VenueModel>> getAllVenues() => getVenues();

  /// Fetch sessions for an event
  Future<List<SessionModel>> getEventSessions(int eventId) async {
    try {
      final response = await client
          .from('event_sessions')
          .select('*')
          .eq('event_id', eventId)
          .order('session_start_time');
      return (response as List).map((e) => SessionModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting event sessions: $e');
      return [];
    }
  }

  /// Fetch ticket types for a session
  Future<List<TicketTypeModel>> getTicketTypes(int sessionId) async {
    try {
      final response = await client
          .from('ticket_types')
          .select('*')
          .eq('session_id', sessionId)
          .order('price', ascending: false);
      return (response as List).map((e) => TicketTypeModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching ticket types: $e');
      return [];
    }
  }

  /// Fetch physical seats for a venue
  Future<List<SeatModel>> getVenueSeats(int venueId) async {
    try {
      final response = await client
          .from('seats')
          .select('*')
          .eq('venue_id', venueId)
          .order('row_label')
          .order('seat_number');
      return (response as List).map((e) => SeatModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching venue seats: $e');
      return [];
    }
  }

  /// Fetch seat inventory for a session
  Future<List<SeatInventoryModel>> getSeatInventory(int sessionId) async {
    try {
      final response = await client
          .from('seat_inventory')
          .select('*')
          .eq('session_id', sessionId);
      return (response as List).map((e) => SeatInventoryModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching seat inventory: $e');
      return [];
    }
  }

  /// Create a master checkout order
  Future<OrderModel?> createOrder(OrderModel order) async {
    try {
      final data = order.toJson();
      data.remove('id'); // let db assign serial
      final response = await client.from('orders').insert(data).select().single();
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  /// Update order status and payment ID
  Future<bool> updateOrderStatus({
    required int orderId,
    required String paymentStatus,
    required String orderStatus,
    String? razorpayPaymentId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'payment_status': paymentStatus,
        'order_status': orderStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (razorpayPaymentId != null) {
        updateData['razorpay_payment_id'] = razorpayPaymentId;
      }
      await client.from('orders').update(updateData).eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('Error updating order: $e');
      return false;
    }
  }

  /// Create issued tickets for an order
  Future<List<TicketModel>> createTickets(List<TicketModel> ticketsList) async {
    try {
      final data = ticketsList.map((t) {
        final m = t.toJson();
        m.remove('id');
        return m;
      }).toList();
      final response = await client.from('tickets').insert(data).select();
      return (response as List).map((e) => TicketModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error creating tickets: $e');
      return [];
    }
  }

  /// Fetch tickets for an order
  Future<List<TicketModel>> getTicketsByOrderId(int orderId) async {
    try {
      final response =
          await client.from('tickets').select('*').eq('order_id', orderId);
      return (response as List).map((e) => TicketModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching tickets for order: $e');
      return [];
    }
  }

  /// Fetch all tickets by user email or phone
  Future<List<Map<String, dynamic>>> getUserBookings(String userEmail) async {
    try {
      final ordersResponse = await client
          .from('orders')
          .select('*, events(title, title_mr, poster_url, category, venue_id)')
          .eq('user_email', userEmail)
          .eq('order_status', 'confirmed')
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(ordersResponse);
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
      return [];
    }
  }

  /// Gate Ticket Scanner: Validate ticket code and atomically mark used via PostgreSQL RPC
  Future<Map<String, dynamic>> validateAndScanTicket({
    required String ticketCode,
    required String gateName,
    int? scannerUserId,
  }) async {
    try {
      final cleanCode = ticketCode.trim();
      final res = await client.rpc('scan_ticket_atomic', params: {
        'p_ticket_code': cleanCode,
        'p_scanner_user_id': scannerUserId ?? 1,
        'p_gate_name': gateName,
      });

      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        if (map['ticket'] != null && map['ticket'] is Map) {
          map['ticket'] = TicketModel.fromJson(Map<String, dynamic>.from(map['ticket']));
        }
        return map;
      }
      return {
        'success': false,
        'status': 'ERROR',
        'message': 'Unexpected scanner response from server.',
      };
    } catch (e) {
      debugPrint('Error scanning ticket via RPC: $e');
      return {
        'success': false,
        'status': 'ERROR',
        'message': 'Scanning error: $e',
      };
    }
  }

  /// Admin stats
  Future<Map<String, dynamic>> getAdminMetrics() async {
    try {
      final orders = await client
          .from('orders')
          .select('grand_total, ticket_count, order_status')
          .eq('order_status', 'confirmed');

      int totalRevenuePaise = 0;
      int totalTicketsSold = 0;
      for (var o in (orders as List)) {
        totalRevenuePaise += (o['grand_total'] as int? ?? 0);
        totalTicketsSold += (o['ticket_count'] as int? ?? 0);
      }

      final eventsCountRes = await client.from('events').select('id');
      final scansCountRes = await client.from('ticket_scans').select('id');

      return {
        'totalRevenueRupees': totalRevenuePaise / 100.0,
        'totalTicketsSold': totalTicketsSold,
        'totalEvents': (eventsCountRes as List).length,
        'totalScansToday': (scansCountRes as List).length,
      };
    } catch (e) {
      debugPrint('Error getting admin metrics: $e');
      return {
        'totalRevenueRupees': 0.0,
        'totalTicketsSold': 0,
        'totalEvents': 0,
        'totalScansToday': 0,
      };
    }
  }

  /// Create new event (Admin / Organiser)
  Future<EventModel?> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await client.from('events').insert(eventData).select().single();
      return EventModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating event: $e');
      return null;
    }
  }

  /// Update existing event (Admin / Organiser)
  Future<bool> updateEvent(int id, Map<String, dynamic> eventData) async {
    try {
      await client.from('events').update(eventData).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  /// Soft-delete or unpublish event
  Future<bool> toggleEventStatus(int id, String newStatus) async {
    try {
      await client.from('events').update({'status': newStatus}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error toggling event status: $e');
      return false;
    }
  }

  /// Add session and pricing quotas to event
  Future<int?> addEventSession({
    required int eventId,
    required DateTime start,
    required DateTime end,
    required List<Map<String, dynamic>> priceTiers,
  }) async {
    try {
      final sessionRes = await client.from('event_sessions').insert({
        'event_id': eventId,
        'session_start_time': start.toIso8601String(),
        'session_end_time': end.toIso8601String(),
        'status': 'active',
      }).select('id').single();

      final sessionId = sessionRes['id'] as int;

      for (var pt in priceTiers) {
        await client.from('ticket_types').insert({
          'event_id': eventId,
          'session_id': sessionId,
          'name': pt['name'],
          'name_mr': pt['name_mr'] ?? pt['name'],
          'price': pt['price'], // in paise
          'total_quota': pt['total_quota'] ?? 150,
          'available_quota': pt['available_quota'] ?? 150,
          'is_seated': 1,
        });
      }

      return sessionId;
    } catch (e) {
      debugPrint('Error adding event session: $e');
      return null;
    }
  }

  /// Create new venue
  Future<VenueModel?> createVenue(Map<String, dynamic> venueData) async {
    try {
      final response = await client.from('venues').insert(venueData).select().single();
      return VenueModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating venue: $e');
      return null;
    }
  }

  /// Update existing venue
  Future<bool> updateVenue(int id, Map<String, dynamic> venueData) async {
    try {
      await client.from('venues').update(venueData).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating venue: $e');
      return false;
    }
  }

  /// Fetch all checkout orders (Admin / Organiser)
  Future<List<Map<String, dynamic>>> getAllOrders({String? search, String? status, int limit = 50}) async {
    try {
      PostgrestFilterBuilder query = client
          .from('orders')
          .select('*, events(title, title_mr, poster_url, category)');

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('order_status', status);
      }

      final response = await query.order('id', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all orders: $e');
      return [];
    }
  }

  /// Fetch all promo coupons
  Future<List<Map<String, dynamic>>> getCoupons() async {
    try {
      final response = await client.from('coupons').select('*').order('id', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
      return [];
    }
  }

  /// Create new promo coupon
  Future<bool> createCoupon(Map<String, dynamic> couponData) async {
    try {
      await client.from('coupons').insert(couponData);
      return true;
    } catch (e) {
      debugPrint('Error creating coupon: $e');
      return false;
    }
  }

  /// Toggle coupon active status
  Future<bool> toggleCouponActive(int id, bool active) async {
    try {
      await client.from('coupons').update({'active': active ? 1 : 0}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error toggling coupon active: $e');
      return false;
    }
  }

  /// Validate promo coupon against real coupons database table
  Future<Map<String, dynamic>?> validateCoupon(String code, int orderSubtotalPaise) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final res = await client
          .from('coupons')
          .select('*')
          .eq('code', cleanCode)
          .eq('active', 1)
          .maybeSingle();

      if (res == null) {
        return {
          'valid': false,
          'message': 'Invalid coupon code or expired.',
        };
      }

      final minOrder = (res['min_order_value'] as int? ?? 0);
      if (orderSubtotalPaise < minOrder) {
        return {
          'valid': false,
          'message': 'Minimum order value of ₹${(minOrder / 100).toStringAsFixed(0)} required.',
        };
      }

      final discountType = res['discount_type']?.toString();
      final discountVal = (res['discount_value'] as int? ?? 0);
      final maxDiscount = (res['max_discount'] as int? ?? 0);

      int calculatedDiscount = 0;
      if (discountType == 'percentage') {
        calculatedDiscount = (orderSubtotalPaise * discountVal) ~/ 10000;
        if (maxDiscount > 0 && calculatedDiscount > maxDiscount) {
          calculatedDiscount = maxDiscount;
        }
      } else {
        calculatedDiscount = discountVal;
        if (calculatedDiscount > orderSubtotalPaise) calculatedDiscount = orderSubtotalPaise;
      }

      return {
        'valid': true,
        'code': cleanCode,
        'discountPaise': calculatedDiscount,
        'discountType': discountType,
        'discountValue': discountVal,
      };
    } catch (e) {
      debugPrint('Error validating coupon: $e');
      return null;
    }
  }

  /// Fetch registered theatre and event organizers
  Future<List<Map<String, dynamic>>> getOrganizers() async {
    try {
      final response = await client.from('organizers').select('*, users(full_name, email, phone)').order('id');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching organizers: $e');
      return [];
    }
  }

  /// Fetch financial settlements ledger
  Future<List<Map<String, dynamic>>> getSettlements({int? organizerId}) async {
    try {
      PostgrestFilterBuilder query = client.from('settlements').select('*, events(title, title_mr), organizers(company_name)');
      if (organizerId != null) {
        query = query.eq('organizer_id', organizerId);
      }
      final response = await query.order('id', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching settlements: $e');
      return [];
    }
  }

  /// Submit an event proposal (Partner With Us / आयोजक नोंदणी)
  Future<bool> submitPartnerLead(Map<String, dynamic> leadData) async {
    try {
      await client.from('partner_leads').insert(leadData);
      return true;
    } catch (e) {
      debugPrint('Error submitting partner lead: $e');
      return false;
    }
  }

  /// Fetch partner organizer leads
  Future<List<Map<String, dynamic>>> getPartnerLeads() async {
    try {
      final response = await client.from('partner_leads').select('*').order('id', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching partner leads: $e');
      return [];
    }
  }
}

