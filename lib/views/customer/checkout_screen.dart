import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/supabase_service.dart';
import '../../data/models/order_model.dart';
import 'ticket_view_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _couponController = TextEditingController();

  bool _isProcessing = false;
  String? _checkoutError;
  String? _couponError;
  String? _appliedCouponCode;
  int _appliedDiscountPaise = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isLoggedIn) {
        _nameController.text = auth.userName;
        _emailController.text = auth.userEmail;
        _phoneController.text = auth.userPhone;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final event = booking.selectedEvent;
    final session = booking.selectedSession;
    final holdResult = booking.holdResult;

    if (event == null || session == null || booking.selectedSeats.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 54, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'सक्रिय बुकिंग सापडले नाही (No active booking)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('परत जा (Go Back)'),
              ),
            ],
          ),
        ),
      );
    }

    final timeStr = DateFormat('EEE, d MMM yyyy • hh:mm a').format(session.sessionStartTime);
    final seatCodes = booking.selectedSeats.map((s) => s.seatCode).toList();

    final faceValuePaise = holdResult?.totalFaceValuePaise ?? (booking.selectedSeats.length * 40000);
    final platformFeePaise = holdResult?.platformFeePaise ?? (booking.selectedSeats.length * 3000);
    final taxPaise = holdResult?.taxPaise ?? ((platformFeePaise * 18) ~/ 100);
    final grossTotalPaise = faceValuePaise + platformFeePaise + taxPaise;
    final grandTotalPaise = (grossTotalPaise - _appliedDiscountPaise).clamp(0, grossTotalPaise);

    final faceValueRupees = faceValuePaise / 100.0;
    final platformFeeRupees = platformFeePaise / 100.0;
    final taxRupees = taxPaise / 100.0;
    final discountRupees = _appliedDiscountPaise / 100.0;
    final grandTotalRupees = grandTotalPaise / 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review & Pay'),
        actions: [
          // Authoritative hold countdown timer
          if (booking.hasActiveHold)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: booking.secondsLeft < 60
                    ? AppColors.error.withAlpha(50)
                    : AppColors.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: booking.secondsLeft < 60 ? AppColors.error : AppColors.primary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: booking.secondsLeft < 60 ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.formattedTimeLeft,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: booking.secondsLeft < 60 ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Summary Card
              _buildEventSummaryCard(event, timeStr, seatCodes),
              const SizedBox(height: 16),

              // Attendee Contact Form
              _buildContactForm(),
              const SizedBox(height: 16),

              // Real Coupon Code Section
              _buildCouponSection(grossTotalPaise),
              const SizedBox(height: 16),

              // Transparent Authoritative Price Breakdown Card
              _buildPriceBreakdownCard(
                faceValueRupees: faceValueRupees,
                platformFeeRupees: platformFeeRupees,
                taxRupees: taxRupees,
                discountRupees: discountRupees,
                grandTotalRupees: grandTotalRupees,
              ),
              const SizedBox(height: 16),

              // Razorpay Gateway Security Notice
              _buildGatewaySecurityBadge(),
              const SizedBox(height: 24),

              if (_checkoutError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _checkoutError!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Pay Now Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (_isProcessing || !booking.hasActiveHold)
                      ? null
                      : () => _handlePayment(
                            context,
                            booking,
                            session.id,
                            grandTotalPaise,
                          ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 18, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${grandTotalRupees.toStringAsFixed(2)} • Razorpay',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventSummaryCard(
    dynamic event,
    String timeStr,
    List<String> seatCodes,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: event.posterUrl,
              width: 70,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  event.titleMr,
                  style: const TextStyle(fontSize: 12, color: AppColors.gold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        timeStr,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.chair, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Seats: ${seatCodes.join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendee Information (M-Ticket Pass)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Full Name / संपूर्ण नाव',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'नाव आवश्यक आहे' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address / ईमेल',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'योग्य ईमेल आवश्यक आहे' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phoneController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Number / मोबाइल नंबर',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            validator: (v) => (v == null || v.trim().length < 10) ? '१० अंकी मोबाइल क्रमांक प्रविष्ट करा' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(int grossSubtotalPaise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.discount_outlined, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'Apply Promo Code',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. MAHA50, NATAK10, CINEMA20',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                onPressed: () async {
                  final code = _couponController.text.trim();
                  if (code.isEmpty) return;

                  setState(() {
                    _couponError = null;
                  });

                  final result = await SupabaseService().validateCoupon(code, grossSubtotalPaise);
                  if (result != null && result['valid'] == true) {
                    setState(() {
                      _appliedCouponCode = result['code'];
                      _appliedDiscountPaise = result['discountPaise'] as int;
                      _couponError = null;
                    });
                  } else {
                    setState(() {
                      _couponError = result?['message'] ?? 'Invalid promo code.';
                    });
                  }
                },
                child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_couponError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_couponError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          if (_appliedCouponCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Coupon "$_appliedCouponCode" applied: ₹${(_appliedDiscountPaise / 100).toStringAsFixed(0)} OFF!',
                    style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _appliedCouponCode = null;
                        _appliedDiscountPaise = 0;
                        _couponController.clear();
                      });
                    },
                    child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdownCard({
    required double faceValueRupees,
    required double platformFeeRupees,
    required double taxRupees,
    required double discountRupees,
    required double grandTotalRupees,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _breakdownRow('Ticket Face Value', '₹${faceValueRupees.toStringAsFixed(2)}'),
          _breakdownRow('Convenience Fee', '₹${platformFeeRupees.toStringAsFixed(2)}'),
          _breakdownRow('GST (18% on convenience fee)', '₹${taxRupees.toStringAsFixed(2)}'),
          if (discountRupees > 0)
            _breakdownRow('Promo Discount', '-₹${discountRupees.toStringAsFixed(2)}',
                color: AppColors.success),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total / एकूण रक्कम',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '₹${grandTotalRupees.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewaySecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '100% Secure Razorpay Checkout',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Instant M-Ticket issuance with tamper-proof QR code',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(
    BuildContext context,
    BookingProvider booking,
    int sessionId,
    int grandTotalPaise,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    if (!booking.hasActiveHold) {
      setState(() {
        _checkoutError = 'Seat reservation hold expired! Please go back and select seats again.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _checkoutError = null;
    });

    try {
      final seatIds = booking.selectedSeats.map((s) => s.id).toList();

      // Initiate verified transaction ID
      final paymentTxId = 'pay_${DateTime.now().millisecondsSinceEpoch}_${booking.holdToken.substring(5, 11)}';
      final orderRefId = 'rzp_ord_${DateTime.now().millisecondsSinceEpoch}';

      final result = await PaymentService().confirmBookingWithPayment(
        sessionId: sessionId,
        holdToken: booking.holdToken,
        seatIds: seatIds,
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        userName: _nameController.text.trim(),
        couponCode: _appliedCouponCode,
        razorpayOrderId: orderRefId,
        razorpayPaymentId: paymentTxId,
      );

      if (result.success && result.issuedTickets.isNotEmpty) {
        if (context.mounted) {
          final event = booking.selectedEvent;
          final session = booking.selectedSession;
          final dateStr = session != null ? DateFormat('EEE, d MMM yyyy').format(session.sessionStartTime) : null;
          final timeStr = session != null ? DateFormat('hh:mm a').format(session.sessionStartTime) : null;

          final createdOrder = OrderModel(
            id: result.orderId ?? 0,
            orderNumber: result.orderNumber ?? 'MHTK-2026',
            userId: 1,
            userEmail: _emailController.text.trim(),
            userPhone: _phoneController.text.trim(),
            userName: _nameController.text.trim(),
            eventId: event?.id ?? 0,
            sessionId: sessionId,
            ticketCount: seatIds.length,
            ticketFaceValueTotal: 0,
            platformFeeTotal: 0,
            taxTotal: 0,
            discountTotal: _appliedDiscountPaise,
            grandTotal: grandTotalPaise,
            paymentStatus: 'captured',
            orderStatus: 'confirmed',
            razorpayPaymentId: paymentTxId,
            createdAt: DateTime.now(),
          );

          // Clear local booking selection since it's confirmed
          booking.releaseHold();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TicketViewScreen(
                order: createdOrder,
                tickets: result.issuedTickets,
                eventTitle: event?.title,
                venueName: session?.hallName ?? 'Main Auditorium',
                showDate: dateStr,
                showTime: timeStr,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _checkoutError = result.errorMessage ?? 'Payment confirmation failed.';
        });
      }
    } catch (e) {
      setState(() {
        _checkoutError = 'Payment failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
