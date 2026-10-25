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

  /// Generates a cryptographically secure client hold token with TicketGhar hold_ prefix
  String createHoldToken() {
    final raw = const Uuid().v4().replaceAll('-', '');
    final raw2 = const Uuid().v4().replaceAll('-', '');
    return 'hold_$raw$raw2';
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

  /// Releases expired holds for this session via PostgreSQL RPC
  Future<int> releaseExpiredHolds(int sessionId) async {
    try {
      final res = await _client.rpc('release_expired_holds', params: {
        'p_session_id': sessionId,
      });
      return (res is int) ? res : (int.tryParse(res.toString()) ?? 0);
    } catch (e) {
      debugPrint('Error releasing expired holds via RPC: $e');
      return 0;
    }
  }

  /// Releases seats held by this token via PostgreSQL RPC
  Future<bool> releaseUserHold({
    required int sessionId,
    required String holdToken,
    List<int>? seatIds,
  }) async {
    try {
      if (holdToken.isEmpty) return false;

      final res = await _client.rpc('release_seats_hold', params: {
        'p_session_id': sessionId,
        'p_hold_token': holdToken,
        'p_seat_ids': seatIds ?? [],
      });

      if (res is Map && res['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error releasing user hold via RPC: $e');
      return false;
    }
  }

  /// Extends active hold duration
  Future<DateTime?> extendHold({
    required int sessionId,
    required String holdToken,
    int minutes = 5,
  }) async {
    try {
      final res = await _client.rpc('extend_seat_hold', params: {
        'p_session_id': sessionId,
        'p_hold_token': holdToken,
        'p_extension_minutes': minutes,
      });

      if (res is Map && res['success'] == true && res['expires_at'] != null) {
        return DateTime.tryParse(res['expires_at'].toString());
      }
      return null;
    } catch (e) {
      debugPrint('Error extending hold via RPC: $e');
      return null;
    }
  }

  /// Concurrency-safe seat hold reservation calling PostgreSQL RPC hold_seats
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
      final response = await _client.rpc('hold_seats', params: {
        'p_session_id': sessionId,
        'p_seat_ids': seatIds,
        'p_hold_token': holdToken,
        'p_hold_minutes': holdMinutes,
      });

      if (response == null || response is! Map) {
        return HoldResult(
          success: false,
          errorMessage: 'Server did not return a valid hold response.',
          holdToken: holdToken,
        );
      }

      final isSuccess = response['success'] == true;
      if (!isSuccess) {
        return HoldResult(
          success: false,
          errorMessage: response['error']?.toString() ??
              'One or more selected seats are unavailable.',
          holdToken: holdToken,
        );
      }

      final expiresAtStr = response['expires_at']?.toString();
      final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;
      final seatsList = (response['seats'] as List?) ?? [];

      int totalFaceValue = 0;
      final List<int> heldSeatIds = [];

      for (var s in seatsList) {
        if (s is Map) {
          final p = s['price'];
          totalFaceValue += (p is int) ? p : (int.tryParse(p?.toString() ?? '30000') ?? 30000);
          final sid = s['seat_id'];
          if (sid != null) {
            heldSeatIds.add((sid is int) ? sid : int.parse(sid.toString()));
          }
        }
      }

      // Calculate transparent pricing breakdown
      final platformFee = heldSeatIds.length * convenienceFeePerTicketPaise;
      final tax = (platformFee * gstPercent) ~/ 100;
      var grandTotal = totalFaceValue + platformFee + tax;

      return HoldResult(
        success: true,
        holdToken: holdToken,
        expiresAt: expiresAt,
        totalFaceValuePaise: totalFaceValue,
        platformFeePaise: platformFee,
        taxPaise: tax,
        grandTotalPaise: grandTotal,
        heldSeatIds: heldSeatIds.isNotEmpty ? heldSeatIds : seatIds,
      );
    } catch (e) {
      debugPrint('Error holding seats via RPC: $e');
      return HoldResult(
        success: false,
        errorMessage: 'Unable to reserve seats: $e',
        holdToken: holdToken,
      );
    }
  }
}
