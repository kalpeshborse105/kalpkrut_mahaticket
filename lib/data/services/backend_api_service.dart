import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env_config.dart';

/// HTTP client for authoritative TicketGhar / MahaTicket Next.js APIs.
/// Payments, PDF, and email must go through this layer — never fabricate gateway IDs.
class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;
  BackendApiService._internal();

  String get _base => EnvConfig.apiBaseUrl;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final uri = Uri.parse('$_base$path');
    try {
      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      Map<String, dynamic> decoded = {};
      if (response.body.isNotEmpty) {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) {
          decoded = raw;
        } else if (raw is Map) {
          decoded = Map<String, dynamic>.from(raw);
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      final error = decoded['error']?.toString() ??
          decoded['message']?.toString() ??
          'Request failed (${response.statusCode})';
      throw BackendApiException(error, statusCode: response.statusCode, data: decoded);
    } on BackendApiException {
      rethrow;
    } on TimeoutException {
      throw BackendApiException(
        'Server timeout. Check API at $_base and try again.',
        statusCode: 408,
      );
    } catch (e) {
      if (e is BackendApiException) rethrow;
      debugPrint('BackendApi POST $path error: $e');
      throw BackendApiException('Network error: $e');
    }
  }

  /// Creates a pending platform order + Razorpay order; extends seat hold.
  Future<Map<String, dynamic>> createPaymentOrder({
    required int sessionId,
    required List<int> seatIds,
    required String holdToken,
    required String userEmail,
    required String userName,
    required String userPhone,
    String? couponCode,
    String? idempotencyKey,
  }) {
    return _post('/api/payments/create-order', {
      'sessionId': sessionId,
      'seatIds': seatIds,
      'holdToken': holdToken,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      'idempotencyKey': ?idempotencyKey,
    });
  }

  /// Server-side Razorpay HMAC verification + booking confirmation.
  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required int sessionId,
    required List<int> seatIds,
    String? userEmail,
    String? userName,
    String? userPhone,
    String? couponCode,
  }) {
    return _post('/api/payments/verify', {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'sessionId': sessionId,
      'seatIds': seatIds,
      'userEmail': ?userEmail,
      'userName': ?userName,
      'userPhone': ?userPhone,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
    });
  }

  Future<Map<String, dynamic>> requestTicketEmail(String ticketCode) {
    return _post('/api/tickets/${Uri.encodeComponent(ticketCode)}/email', {});
  }

  /// Authoritative gate scan (MTGRP/MTSEC decrypt + event/session/seat match).
  Future<Map<String, dynamic>> verifyGateScan({
    required String ticketCodeOrPayload,
    required String gateName,
    int? scannerUserId,
    int? targetEventId,
    int? targetSessionId,
    int? scannerOrganizerId,
    bool requireScope = false,
  }) {
    return _post('/api/scanner/verify', {
      'ticketCodeOrPayload': ticketCodeOrPayload,
      'gateName': gateName,
      'scannerUserId': ?scannerUserId,
      'targetEventId': ?targetEventId,
      'targetSessionId': ?targetSessionId,
      'scannerOrganizerId': ?scannerOrganizerId,
      'requireScope': requireScope,
      'scannerDevice': 'MahaTicket Flutter Gate',
    });
  }
}

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  BackendApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}
