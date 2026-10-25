import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import 'supabase_service.dart';

class PaymentResult {
  final bool success;
  final String? errorMessage;
  final String? paymentId;
  final String? orderNumber;
  final int? orderId;
  final List<TicketModel> issuedTickets;

  PaymentResult({
    required this.success,
    this.errorMessage,
    this.paymentId,
    this.orderNumber,
    this.orderId,
    this.issuedTickets = const [],
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final SupabaseClient _client = SupabaseService().client;

  /// Confirm payment and atomically finalize booking via PostgreSQL RPC confirm_booking_order.
  /// This operation:
  /// 1. Authoritatively validates the active hold token in the database.
  /// 2. Enforces idempotency (cannot process the same payment twice).
  /// 3. Computes authoritative total and discounts on the server.
  /// 4. Finalizes seat inventory to 'booked' atomically.
  /// 5. Issues cryptographically signed tickets and QR codes.
  Future<PaymentResult> confirmBookingWithPayment({
    required int sessionId,
    required String holdToken,
    required List<int> seatIds,
    required String userEmail,
    required String userPhone,
    required String userName,
    String? couponCode,
    String? razorpayOrderId,
    required String razorpayPaymentId,
    String? idempotencyKey,
  }) async {
    try {
      if (razorpayPaymentId.isEmpty) {
        return PaymentResult(
          success: false,
          errorMessage: 'Valid payment confirmation ID required.',
        );
      }

      final key = idempotencyKey ??
          'idem_${sessionId}_${razorpayPaymentId}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _client.rpc('confirm_booking_order', params: {
        'p_session_id': sessionId,
        'p_hold_token': holdToken,
        'p_seat_ids': seatIds,
        'p_user_email': userEmail,
        'p_user_phone': userPhone,
        'p_user_name': userName,
        'p_coupon_code': couponCode,
        'p_razorpay_order_id': razorpayOrderId,
        'p_razorpay_payment_id': razorpayPaymentId,
        'p_idempotency_key': key,
      });

      if (response == null || response is! Map) {
        return PaymentResult(
          success: false,
          errorMessage: 'Server returned an invalid booking confirmation response.',
        );
      }

      final isSuccess = response['success'] == true;
      if (!isSuccess) {
        return PaymentResult(
          success: false,
          errorMessage: response['error']?.toString() ??
              'Unable to confirm booking. Active hold may have expired.',
        );
      }

      final orderId = (response['order_id'] is int)
          ? response['order_id'] as int
          : int.tryParse(response['order_id']?.toString() ?? '0');
      final orderNumber = response['order_number']?.toString();
      final ticketsJson = (response['tickets'] as List?) ?? [];

      final List<TicketModel> ticketsList = [];
      for (var t in ticketsJson) {
        if (t is Map) {
          ticketsList.add(TicketModel.fromJson(Map<String, dynamic>.from(t)));
        }
      }

      return PaymentResult(
        success: true,
        orderId: orderId,
        orderNumber: orderNumber,
        paymentId: razorpayPaymentId,
        issuedTickets: ticketsList,
      );
    } catch (e) {
      debugPrint('Error confirming booking via RPC: $e');
      return PaymentResult(
        success: false,
        errorMessage: 'Booking confirmation error: $e',
      );
    }
  }
}
