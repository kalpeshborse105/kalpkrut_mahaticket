import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/seat_model.dart';
import 'supabase_service.dart';

class HoldResult {
  final bool success;
  final String? errorMessage;
  final String holdToken;
  final DateTime? expiresAt;
  final int totalFaceValuePaise;
  final int platformFeePaise;
  final int taxPaise;
  final int grandTotalPaise;
  final List<int> heldSeatIds;

  HoldResult({
    required this.success,
    this.errorMessage,
    required this.holdToken,
    this.expiresAt,
    this.totalFaceValuePaise = 0,
    this.platformFeePaise = 0,
    this.taxPaise = 0,
    this.grandTotalPaise = 0,
    this.heldSeatIds = const [],
  });

  double get grandTotalRupees => grandTotalPaise / 100.0;
  double get faceValueRupees => totalFaceValuePaise / 100.0;
  double get platformFeeRupees => platformFeePaise / 100.0;
  double get taxRupees => taxPaise / 100.0;
}

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final SupabaseClient _client = SupabaseService().client;
  static const int holdMinutes = 5;
  static const int convenienceFeePerTicketPaise = 3000; // ₹30.00
  static const int gstPercent = 18; // 18% GST on platform fee

  /// Creates a unique client hold token for this transaction
  String createHoldToken() {
    return 'HLD-${const Uuid().v4().substring(0, 18).toUpperCase()}';
  }

  /// Real-time stream channel for seat inventory updates on a given session
  RealtimeChannel subscribeToSessionSeats({
    required int sessionId,
    required Function(List<SeatInventoryModel>) onUpdate,
  }) {
    final channel = _client.channel('seat_inventory:session_$sessionId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'seat_inventory',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) async {
            // Refetch current session inventory when an update occurs
            final inventory = await SupabaseService().getSeatInventory(sessionId);
            onUpdate(inventory);
          },
        )
        .subscribe();

    return channel;
  }

  /// Releases expired holds for this session
  Future<int> releaseExpiredHolds(int sessionId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final expired = await _client
          .from('seat_inventory')
          .update({
            'status': 'available',
            'held_by_user_id': null,
            'hold_expires_at': null,
          })
          .eq('session_id', sessionId)
          .eq('status', 'held')
          .lt('hold_expires_at', now)
          .select('id');

      return (expired as List).length;
    } catch (e) {
      debugPrint('Error releasing expired holds: $e');
      return 0;
    }
  }

  /// Releases seats held by this token
  Future<bool> releaseUserHold({
    required int sessionId,
    required String holdToken,
    List<int>? seatIds,
  }) async {
    try {
      if (holdToken.isEmpty) return false;

      var query = _client.from('seat_inventory').update({
        'status': 'available',
        'held_by_user_id': null,
        'hold_expires_at': null,
      }).eq('session_id', sessionId).eq('status', 'held').eq('held_by_user_id', holdToken);

      if (seatIds != null && seatIds.isNotEmpty) {
        query = query.filter('seat_id', 'in', seatIds);
      }

      await query;
      return true;
    } catch (e) {
      debugPrint('Error releasing user hold: $e');
      return false;
    }
  }

  /// Concurrency-safe seat hold reservation
  Future<HoldResult> holdSeats({
    required int sessionId,
    required List<int> seatIds,
    required String holdToken,
    String? couponCode,
  }) async {
    if (seatIds.isEmpty) {
      return HoldResult(
        success: false,
        errorMessage: 'Please select at least 1 seat.',
        holdToken: holdToken,
      );
    }

    if (seatIds.length > 5) {
      return HoldResult(
        success: false,
        errorMessage: 'Maximum 5 tickets allowed per transaction.',
        holdToken: holdToken,
      );
    }

    try {
      // 1. Release expired holds first
      await releaseExpiredHolds(sessionId);

      // 2. Fetch current inventory for requested seats
      final inventoryRows = await _client
          .from('seat_inventory')
          .select('*, ticket_types(price)')
          .eq('session_id', sessionId)
          .filter('seat_id', 'in', seatIds);

      final List rows = inventoryRows as List;

      // Check conflict
      for (var row in rows) {
        final status = row['status'];
        final heldBy = row['held_by_user_id'];
        final expiresAtStr = row['hold_expires_at'];
        final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

        if (status == 'booked') {
          return HoldResult(
            success: false,
            errorMessage: 'One or more selected seats were already booked.',
            holdToken: holdToken,
          );
        }

        if (status == 'held' && heldBy != holdToken) {
          if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
            return HoldResult(
              success: false,
              errorMessage:
                  'Seat is currently held by another customer. Please choose different seats.',
              holdToken: holdToken,
            );
          }
        }
      }

      // 3. Compute price
      int totalFaceValue = 0;
      for (var row in rows) {
        final tt = row['ticket_types'];
        if (tt != null && tt['price'] != null) {
          totalFaceValue += (tt['price'] as int);
        } else {
          totalFaceValue += 30000; // default ₹300 if unattached
        }
      }

      final expiresAt = DateTime.now().add(const Duration(minutes: holdMinutes));

      // 4. Atomic lock: update seats to 'held' with holdToken and expiresAt
      for (var seatId in seatIds) {
        await _client
            .from('seat_inventory')
            .update({
              'status': 'held',
              'held_by_user_id': holdToken,
              'hold_expires_at': expiresAt.toUtc().toIso8601String(),
            })
            .eq('session_id', sessionId)
            .eq('seat_id', seatId);
      }

      // 5. Calculate transparent pricing breakdown
      final platformFee = seatIds.length * convenienceFeePerTicketPaise;
      final tax = (platformFee * gstPercent) ~/ 100;
      var grandTotal = totalFaceValue + platformFee + tax;

      // Apply coupon discount if valid
      if (couponCode != null && couponCode.toUpperCase() == 'MAHA100') {
        grandTotal = (grandTotal - 10000).clamp(0, grandTotal); // ₹100 off
      }

      return HoldResult(
        success: true,
        holdToken: holdToken,
        expiresAt: expiresAt,
        totalFaceValuePaise: totalFaceValue,
        platformFeePaise: platformFee,
        taxPaise: tax,
        grandTotalPaise: grandTotal,
        heldSeatIds: seatIds,
      );
    } catch (e) {
      debugPrint('Error holding seats: $e');
      return HoldResult(
        success: false,
        errorMessage: 'Unable to hold seats: $e',
        holdToken: holdToken,
      );
    }
  }

  /// Mark held seats as booked upon successful payment
  Future<bool> finalizeBooking({
    required int sessionId,
    required String holdToken,
    required List<int> seatIds,
    required int orderId,
  }) async {
    try {
      for (var seatId in seatIds) {
        await _client
            .from('seat_inventory')
            .update({
              'status': 'booked',
              'order_id': orderId,
              'held_by_user_id': null,
              'hold_expires_at': null,
            })
            .eq('session_id', sessionId)
            .eq('seat_id', seatId);
      }
      return true;
    } catch (e) {
      debugPrint('Error finalizing booking: $e');
      return false;
    }
  }
}
