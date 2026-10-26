import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/ticket_model.dart';
import 'backend_api_service.dart';
import 'razorpay_checkout.dart';

class PaymentResult {
  final bool success;
  final String? errorMessage;
  final String? paymentId;
  final String? orderNumber;
  final int? orderId;
  final List<TicketModel> issuedTickets;
  final OrderModel? order;

  PaymentResult({
    required this.success,
    this.errorMessage,
    this.paymentId,
    this.orderNumber,
    this.orderId,
    this.issuedTickets = const [],
    this.order,
  });
}

/// Authoritative checkout: create-order → Razorpay → server verify.
/// Never fabricates payment IDs or confirms bookings from client-only success callbacks.
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final BackendApiService _api = BackendApiService();
  RazorpayCheckoutGateway? _gateway;

  Future<PaymentResult> checkoutWithRazorpay({
    required int sessionId,
    required String holdToken,
    required List<int> seatIds,
    required String userEmail,
    required String userPhone,
    required String userName,
    required String eventTitle,
    String? couponCode,
  }) async {
    if (holdToken.isEmpty || !holdToken.startsWith('hold_')) {
      return PaymentResult(
        success: false,
        errorMessage: 'Invalid seat hold. Please select seats again.',
      );
    }
    if (seatIds.isEmpty || seatIds.length > 5) {
      return PaymentResult(
        success: false,
        errorMessage: 'Select between 1 and 5 seats to continue.',
      );
    }

    try {
      // 1) Trusted backend creates Razorpay order + extends hold
      final created = await _api.createPaymentOrder(
        sessionId: sessionId,
        seatIds: seatIds,
        holdToken: holdToken,
        userEmail: userEmail,
        userName: userName,
        userPhone: userPhone,
        couponCode: couponCode,
        idempotencyKey: 'ord_$holdToken',
      );

      final razorpayOrderId = created['orderId']?.toString() ?? '';
      final keyId = created['keyId']?.toString() ?? '';
      final amount = created['amount'] is int
          ? created['amount'] as int
          : int.tryParse('${created['amount']}') ?? 0;
      final currency = created['currency']?.toString() ?? 'INR';

      if (razorpayOrderId.isEmpty || keyId.isEmpty || amount <= 0) {
        return PaymentResult(
          success: false,
          errorMessage: created['error']?.toString() ??
              'Could not create payment order. Please reselect seats.',
        );
      }

      // 2) Open Razorpay Checkout (Android SDK / web Checkout.js)
      _gateway?.dispose();
      _gateway = RazorpayCheckoutGateway();
      final paid = await _gateway!.open(
        keyId: keyId,
        razorpayOrderId: razorpayOrderId,
        amountPaise: amount,
        currency: currency,
        name: 'MahaTicket',
        description: eventTitle,
        prefillName: userName,
        prefillEmail: userEmail,
        prefillContact: userPhone,
      );

      // 3) Server-side signature verification (authoritative confirm)
      Map<String, dynamic>? verified;
      Object? lastError;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          verified = await _api.verifyPayment(
            razorpayOrderId: paid.orderId,
            razorpayPaymentId: paid.paymentId,
            razorpaySignature: paid.signature,
            sessionId: sessionId,
            seatIds: seatIds,
            userEmail: userEmail,
            userName: userName,
            userPhone: userPhone,
            couponCode: couponCode,
          );
          if (verified['success'] == true || verified['verified'] == true) {
            break;
          }
          lastError = verified['error'] ?? 'Verification failed';
        } catch (e) {
          lastError = e;
          debugPrint('verify attempt $attempt failed: $e');
          if (attempt < 3) {
            await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          }
        }
      }

      if (verified == null ||
          (verified['success'] != true && verified['verified'] != true)) {
        return PaymentResult(
          success: false,
          errorMessage:
              'Payment received but verification is pending. Do not pay again — contact support with payment ID ${paid.paymentId}. Detail: $lastError',
          paymentId: paid.paymentId,
        );
      }

      if (verified['reconciliationRequired'] == true) {
        return PaymentResult(
          success: false,
          errorMessage: verified['error']?.toString() ??
              'Payment captured but seats need reconciliation. Support will help with ${paid.paymentId}.',
          paymentId: paid.paymentId,
        );
      }

      final orderJson = verified['order'] is Map
          ? Map<String, dynamic>.from(verified['order'] as Map)
          : verified;
      final ticketsRaw = (verified['tickets'] as List?) ??
          (orderJson['tickets'] as List?) ??
          const [];

      final groupQr = orderJson['groupQrPayload']?.toString() ??
          orderJson['group_qr_payload']?.toString() ??
          verified['groupQrPayload']?.toString();

      final tickets = <TicketModel>[];
      for (final t in ticketsRaw) {
        if (t is Map) {
          final map = Map<String, dynamic>.from(t);
          if ((map['groupQrPayload'] == null && map['group_qr_payload'] == null) &&
              groupQr != null &&
              groupQr.isNotEmpty) {
            map['groupQrPayload'] = groupQr;
          }
          tickets.add(TicketModel.fromJson(map));
        }
      }

      final order = OrderModel.fromJson(_normalizeOrderJson(orderJson, paid.paymentId));

      return PaymentResult(
        success: tickets.isNotEmpty,
        orderId: order.id,
        orderNumber: order.orderNumber,
        paymentId: paid.paymentId,
        issuedTickets: tickets,
        order: order,
        errorMessage: tickets.isEmpty
            ? 'Payment verified but tickets were not returned. Check My Tickets shortly.'
            : null,
      );
    } on BackendApiException catch (e) {
      return PaymentResult(success: false, errorMessage: e.message);
    } catch (e) {
      debugPrint('checkoutWithRazorpay error: $e');
      final msg = e.toString();
      if (msg.contains('cancelled') || msg.contains('Payment cancelled')) {
        return PaymentResult(
          success: false,
          errorMessage: 'Payment cancelled. Your seats remain held until the timer expires.',
        );
      }
      return PaymentResult(
        success: false,
        errorMessage: msg.replaceFirst('StateError: ', '').replaceFirst('Exception: ', ''),
      );
    } finally {
      _gateway?.dispose();
      _gateway = null;
    }
  }

  Map<String, dynamic> _normalizeOrderJson(Map<String, dynamic> raw, String paymentId) {
    return {
      'id': raw['id'] ?? raw['platformOrderId'] ?? 0,
      'order_number': raw['order_number'] ?? raw['orderNumber'] ?? '',
      'user_id': raw['user_id'] ?? raw['userId'] ?? 0,
      'user_email': raw['user_email'] ?? raw['userEmail'] ?? '',
      'user_phone': raw['user_phone'] ?? raw['userPhone'] ?? '',
      'user_name': raw['user_name'] ?? raw['userName'] ?? '',
      'event_id': raw['event_id'] ?? raw['eventId'] ?? 0,
      'session_id': raw['session_id'] ?? raw['sessionId'] ?? 0,
      'ticket_count': raw['ticket_count'] ?? raw['ticketCount'] ?? 0,
      'ticket_face_value_total':
          raw['ticket_face_value_total'] ?? raw['ticketFaceValueTotal'] ?? 0,
      'platform_fee_total': raw['platform_fee_total'] ?? raw['platformFeeTotal'] ?? 0,
      'tax_total': raw['tax_total'] ?? raw['taxTotal'] ?? 0,
      'discount_total': raw['discount_total'] ?? raw['discountTotal'] ?? 0,
      'grand_total': raw['grand_total'] ?? raw['grandTotal'] ?? 0,
      'payment_status': raw['payment_status'] ?? raw['paymentStatus'] ?? 'captured',
      'order_status': raw['order_status'] ?? raw['orderStatus'] ?? 'confirmed',
      'razorpay_order_id': raw['razorpay_order_id'] ?? raw['razorpayOrderId'],
      'razorpay_payment_id':
          raw['razorpay_payment_id'] ?? raw['razorpayPaymentId'] ?? paymentId,
      'created_at': raw['created_at'] ?? raw['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }
}
