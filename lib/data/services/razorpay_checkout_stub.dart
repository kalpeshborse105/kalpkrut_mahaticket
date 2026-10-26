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

/// Platform checkout entry. Stub never completes a payment.
class RazorpayCheckoutGateway {
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
    throw UnsupportedError(
      'Razorpay Checkout is not available on this platform. Use Android app or enable web checkout.',
    );
  }

  void dispose() {}
}
