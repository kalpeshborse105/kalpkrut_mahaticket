import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

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

/// Flutter web Razorpay Checkout.js (loaded on demand).
class RazorpayCheckoutGateway {
  Future<void> _ensureScript() async {
    if (web.window.getProperty('Razorpay'.toJS) != null) return;

    final completer = Completer<void>();
    final script = web.HTMLScriptElement()
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..async = true;
    script.onload = (web.Event _) {
      if (!completer.isCompleted) completer.complete();
    }.toJS;
    script.onerror = (web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Failed to load Razorpay Checkout.js'));
      }
    }.toJS;
    web.document.head!.appendChild(script);
    await completer.future.timeout(const Duration(seconds: 20));
  }

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
    await _ensureScript();
    final completer = Completer<RazorpayPaymentSuccess>();

    final contact = prefillContact.startsWith('+')
        ? prefillContact
        : '+91${prefillContact.replaceFirst(RegExp(r'^0+'), '')}';

    final options = <String, Object?>{
      'key': keyId,
      'amount': amountPaise,
      'currency': currency,
      'name': name,
      'description': description.length > 255 ? description.substring(0, 255) : description,
      'order_id': razorpayOrderId,
      'prefill': <String, String>{
        'name': prefillName,
        'email': prefillEmail,
        'contact': contact,
      },
      'theme': <String, String>{'color': '#EA580C'},
      'handler': (JSObject response) {
        final paymentId = response.getProperty('razorpay_payment_id'.toJS)?.dartify()?.toString() ?? '';
        final orderId = response.getProperty('razorpay_order_id'.toJS)?.dartify()?.toString() ?? razorpayOrderId;
        final signature = response.getProperty('razorpay_signature'.toJS)?.dartify()?.toString() ?? '';
        if (completer.isCompleted) return;
        if (paymentId.isEmpty || signature.isEmpty) {
          completer.completeError(StateError('Incomplete Razorpay web success payload.'));
        } else {
          completer.complete(RazorpayPaymentSuccess(
            paymentId: paymentId,
            orderId: orderId,
            signature: signature,
          ));
        }
      }.toJS,
      'modal': <String, Object?>{
        'ondismiss': () {
          if (!completer.isCompleted) {
            completer.completeError(StateError('Payment cancelled by user.'));
          }
        }.toJS,
      },
    };

    final razorpayCtor = web.window.getProperty('Razorpay'.toJS);
    if (razorpayCtor == null) {
      throw StateError('Razorpay global missing after script load.');
    }

    final instance = (razorpayCtor as JSFunction).callAsConstructor(options.jsify());
    (instance as JSObject).callMethod('open'.toJS);
    return completer.future;
  }

  void dispose() {}
}
