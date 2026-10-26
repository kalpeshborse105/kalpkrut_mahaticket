import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentSuccess {
  final String paymentId;
  final String orderId;
  final String signature;

  const RazorpayPaymentSuccess({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

/// Android / iOS Razorpay Checkout via official plugin.
class RazorpayCheckoutGateway {
  Razorpay? _razorpay;

  Future<RazorpayPaymentSuccess> open({
    required String keyId,
    required String razorpayOrderId,
    required int amountPaise,
    required String currency,
    required String name,
    required String description,
    required String prefillName,
    required String prefillEmail,
    required String prefillContact,
  }) async {
    final completer = Completer<RazorpayPaymentSuccess>();
    final razorpay = Razorpay();
    _razorpay = razorpay;

    void clearHandlers() {
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (completer.isCompleted) return;
      final paymentId = response.paymentId ?? '';
      final orderId = response.orderId ?? razorpayOrderId;
      final signature = response.signature ?? '';
      if (paymentId.isEmpty || signature.isEmpty) {
        completer.completeError(
          StateError('Razorpay returned an incomplete success payload.'),
        );
      } else {
        completer.complete(RazorpayPaymentSuccess(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        ));
      }
      clearHandlers();
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      final code = response.code;
      final message = response.message ?? 'Payment cancelled or failed';
      completer.completeError(StateError('Razorpay error [$code]: $message'));
      clearHandlers();
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      debugPrint('External wallet selected: ${response.walletName}');
    });

    final options = <String, dynamic>{
      'key': keyId,
      'amount': amountPaise,
      'currency': currency,
      'name': name,
      'description': description.length > 255 ? description.substring(0, 255) : description,
      'order_id': razorpayOrderId,
      'prefill': {
        'name': prefillName,
        'email': prefillEmail,
        'contact': prefillContact.startsWith('+')
            ? prefillContact
            : '+91${prefillContact.replaceFirst(RegExp(r'^0+'), '')}',
      },
      'theme': {'color': '#EA580C'},
      'retry': {'enabled': true, 'max_count': 2},
    };

    try {
      razorpay.open(options);
    } catch (e) {
      clearHandlers();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
