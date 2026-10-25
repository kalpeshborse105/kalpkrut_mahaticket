import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/env_config.dart';
import '../../providers/booking_provider.dart';
import '../../data/services/payment_service.dart';
import 'ticket_view_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Kalpesh Borse');
  final _emailController = TextEditingController(text: 'kalpeshborse105@gmail.com');
  final _phoneController = TextEditingController(text: '+91 9876543210');
  final _couponController = TextEditingController();

  bool _isProcessing = false;
  String? _checkoutError;

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
        body: const Center(child: Text('No active booking found')),
      );
    }

    final timeStr = DateFormat('EEE, d MMM yyyy • hh:mm a').format(session.sessionStartTime);
    final seatCodes = booking.selectedSeats.map((s) => s.seatCode).toList();

    final faceValueRupees = (holdResult?.totalFaceValuePaise ?? (booking.selectedSeats.length * 40000)) / 100.0;
    final platformFeeRupees = (holdResult?.platformFeePaise ?? (booking.selectedSeats.length * 3000)) / 100.0;
    final taxRupees = (holdResult?.taxPaise ?? ((platformFeeRupees * 100 * 0.18).toInt())) / 100.0;
    final discountRupees = (booking.couponCode != null && booking.couponCode == 'MAHA100') ? 100.0 : 0.0;
    final grandTotalRupees = (faceValueRupees + platformFeeRupees + taxRupees - discountRupees).clamp(0.0, 99999.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Pay'),
        actions: [
          // Hold countdown timer
          if (booking.hasActiveHold)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: booking.secondsLeft < 60
                    ? AppColors.error.withAlpha(50)
                    : AppColors.gold.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: booking.secondsLeft < 60 ? AppColors.error : AppColors.gold,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: booking.secondsLeft < 60 ? AppColors.error : AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.formattedTimeLeft,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: booking.secondsLeft < 60 ? AppColors.error : AppColors.gold,
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

              // Coupon Code Card
              _buildCouponSection(booking),
              const SizedBox(height: 16),

              // Price Breakdown Card
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
                  child: Text(
                    _checkoutError!,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () => _handlePayment(
                            context,
                            booking,
                            event.id,
                            session.id,
                            seatCodes,
                            (grandTotalRupees * 100).toInt(),
                            (faceValueRupees * 100).toInt(),
                            (platformFeeRupees * 100).toInt(),
                            (taxRupees * 100).toInt(),
                            (discountRupees * 100).toInt(),
                          ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Pay ₹${grandTotalRupees.toStringAsFixed(2)} with Razorpay',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    fontSize: 16,
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
                    Text(
                      'Seats: ${seatCodes.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
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
                (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
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
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter mobile number' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(BookingProvider booking) {
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
                    hintText: 'Try "MAHA100" for ₹100 OFF',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                ),
                onPressed: () {
                  booking.applyCoupon(_couponController.text);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
          if (booking.couponCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Coupon "${booking.couponCode}" applied successfully!',
                    style: const TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      booking.removeCoupon();
                      _couponController.clear();
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
            _breakdownRow('Special Promo Discount', '-₹${discountRupees.toStringAsFixed(2)}',
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
                  'Key: ${EnvConfig.razorpayKeyId} • Instant M-Ticket issuance',
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
    int eventId,
    int sessionId,
    List<String> seatCodes,
    int grandTotalPaise,
    int faceValuePaise,
    int platformFeePaise,
    int taxPaise,
    int discountPaise,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _checkoutError = null;
    });

    try {
      final seatIds = booking.selectedSeats.map((s) => s.id).toList();

      final result = await PaymentService().processCheckout(
        eventId: eventId,
        sessionId: sessionId,
        holdToken: booking.holdToken,
        seatIds: seatIds,
        seatCodes: seatCodes,
        ticketTypeId: booking.ticketTypes.isNotEmpty ? booking.ticketTypes.first.id : 1,
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        totalFaceValuePaise: faceValuePaise,
        platformFeePaise: platformFeePaise,
        taxPaise: taxPaise,
        discountPaise: discountPaise,
        grandTotalPaise: grandTotalPaise,
      );

      if (result.success && result.issuedTickets.isNotEmpty) {
        if (context.mounted) {
          final event = booking.selectedEvent;
          final session = booking.selectedSession;
          final dateStr = session != null ? DateFormat('EEE, d MMM yyyy').format(session.sessionStartTime) : null;
          final timeStr = session != null ? DateFormat('hh:mm a').format(session.sessionStartTime) : null;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TicketViewScreen(
                order: result.order!,
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
