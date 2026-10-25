import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/seat_model.dart';
import 'checkout_screen.dart';

class SeatMatrixScreen extends StatelessWidget {
  const SeatMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final event = booking.selectedEvent;
    final session = booking.selectedSession;

    final timeStr = session != null
        ? DateFormat('EEE, d MMM • hh:mm a').format(session.sessionStartTime)
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event?.title ?? 'Seat Selection',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeStr,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          // 5-Minute Live Hold Timer Pill
          if (booking.hasActiveHold)
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: booking.secondsLeft < 60
                    ? AppColors.error.withAlpha(45)
                    : AppColors.primary.withAlpha(35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: booking.secondsLeft < 60 ? AppColors.error : AppColors.primary,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
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
      body: booking.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'आसन व्यवस्था लोड होत आहे... (Loading seat map)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Conflict or error banner if any
                if (booking.conflictError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    color: AppColors.error.withAlpha(220),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            booking.conflictError!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Seat Legend
                _buildLegend(),

                // Real Interactive Zoomable Auditorium Layout
                Expanded(
                  child: booking.venueSeats.isEmpty
                      ? _buildEmptySeatsView()
                      : InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 2.8,
                          boundaryMargin: const EdgeInsets.all(60),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            child: Column(
                              children: [
                                // Stage / Screen Curved Bar
                                _buildScreenArc(),
                                const SizedBox(height: 36),

                                // Real sections and physical seats grouped by Tier
                                ..._buildRealTierSections(context, booking),

                                const SizedBox(height: 60),
                              ],
                            ),
                          ),
                        ),
                ),

                // Bottom Bar (Selected seats & Proceed)
                _buildBottomBar(context, booking),
              ],
            ),
    );
  }

  Widget _buildEmptySeatsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_outlined, size: 64, color: AppColors.textMuted.withAlpha(120)),
            const SizedBox(height: 16),
            const Text(
              'आसन व्यवस्था उपलब्ध नाही',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'या थिएटरसाठी डिजिटल सीटमॅप अद्याप कॉन्फिगर केलेले नाही.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Available', AppColors.seatAvailableBorder, false),
          _legendItem('Selected', AppColors.primary, true),
          _legendItem('Held (Locked)', AppColors.gold, true),
          _legendItem('Booked', AppColors.seatBooked, true),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, bool filled) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildScreenArc() {
    return Column(
      children: [
        Container(
          width: 300,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.cyan.withAlpha(220),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(90)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withAlpha(160),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'STAGE / SCREEN (रंगमंच)',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRealTierSections(BuildContext context, BookingProvider booking) {
    // Group physical seats by Tier
    final Map<String, List<SeatModel>> tierGroups = {};
    for (var seat in booking.venueSeats) {
      final tierKey = seat.tier.toLowerCase().trim();
      tierGroups.putIfAbsent(tierKey, () => []).add(seat);
    }

    final List<Widget> widgets = [];

    tierGroups.forEach((tier, seatsInTier) {
      // Find authoritative price for this tier from ticketTypes
      final matchingTicketType = booking.ticketTypes.firstWhere(
        (tt) => tt.name.toLowerCase().contains(tier) || tt.nameMr.toLowerCase().contains(tier),
        orElse: () => booking.ticketTypes.isNotEmpty
            ? booking.ticketTypes.first
            : TicketTypeModel(
                id: 1,
                eventId: 0,
                sessionId: 0,
                name: tier.toUpperCase(),
                nameMr: tier,
                price: 30000,
              ),
      );

      final priceRupees = (matchingTicketType.price / 100.0).toStringAsFixed(0);

      // Group seats in this tier by row_label
      final Map<String, List<SeatModel>> rowGroups = {};
      for (var seat in seatsInTier) {
        rowGroups.putIfAbsent(seat.rowLabel, () => []).add(seat);
      }

      // Sort rows alphabetically
      final sortedRowKeys = rowGroups.keys.toList()..sort();

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              // Tier Header Pill
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTierLabel(tier),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹$priceRupees',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),

              // Rows of physical seats
              ...sortedRowKeys.map((rowLabel) {
                final rowSeats = rowGroups[rowLabel]!
                  ..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left row label
                      SizedBox(
                        width: 22,
                        child: Text(
                          rowLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Real physical seats
                      ...rowSeats.map((seat) => _buildPhysicalSeatTile(booking, seat)),

                      const SizedBox(width: 8),
                      // Right row label
                      SizedBox(
                        width: 22,
                        child: Text(
                          rowLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  String _formatTierLabel(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return 'Platinum / प्लॅटिनम';
      case 'gold':
        return 'Gold / सुवर्ण';
      case 'silver':
        return 'Silver / सिल्व्हर';
      case 'balcony':
        return 'Balcony / बाल्कनी';
      case 'premium':
        return 'Premium / प्रीमियम';
      case 'box':
        return 'Box / बैठक';
      default:
        return '${tier.toUpperCase()} / स्टँडर्ड';
    }
  }

  Widget _buildPhysicalSeatTile(BookingProvider booking, SeatModel seat) {
    // 1. Is selected by current customer
    final isSelected = booking.selectedSeats.any((s) => s.id == seat.id);

    // 2. Query session inventory for availability
    final inv = booking.inventory.firstWhere(
      (i) => i.seatId == seat.id,
      orElse: () => SeatInventoryModel(
        id: 0,
        sessionId: booking.selectedSession?.id ?? 0,
        seatId: seat.id,
        ticketTypeId: 1,
        status: seat.isBlocked == 1 ? 'blocked' : 'available',
      ),
    );

    final isBooked = inv.status == 'booked';
    final isBlocked = seat.isBlocked == 1 || inv.status == 'blocked';
    final isHeldByOther = inv.status == 'held' &&
        !inv.isExpired &&
        inv.heldByUserId != booking.holdToken;

    Color seatColor = Colors.transparent;
    Color borderColor = AppColors.seatAvailableBorder;
    Widget? innerWidget;

    if (isSelected) {
      seatColor = AppColors.primary;
      borderColor = AppColors.primary;
      innerWidget = Text(
        '${seat.seatNumber}',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    } else if (isBooked) {
      seatColor = AppColors.seatBooked;
      borderColor = AppColors.seatBooked;
      innerWidget = const Icon(Icons.close, size: 9, color: AppColors.textMuted);
    } else if (isBlocked) {
      seatColor = AppColors.surfaceLight;
      borderColor = Colors.white10;
      innerWidget = const Icon(Icons.block, size: 8, color: AppColors.textMuted);
    } else if (isHeldByOther) {
      seatColor = AppColors.gold.withAlpha(50);
      borderColor = AppColors.gold;
      innerWidget = const Icon(Icons.lock, size: 8, color: AppColors.gold);
    } else {
      seatColor = Colors.transparent;
      borderColor = AppColors.seatAvailableBorder;
      innerWidget = Text(
        '${seat.seatNumber}',
        style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
      );
    }

    final isTappable = !isBooked && !isBlocked && !isHeldByOther;

    return GestureDetector(
      onTap: isTappable ? () => booking.toggleSeat(seat) : null,
      child: Container(
        width: 25,
        height: 25,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(150),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(child: innerWidget),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BookingProvider booking) {
    final selectedCount = booking.selectedSeats.length;
    final totalPaise = booking.holdResult?.grandTotalPaise ?? (selectedCount * 45000);
    final totalRupees = totalPaise / 100.0;
    final seatCodesStr = booking.selectedSeats.map((s) => s.seatCode).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(190),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCount > 0
                        ? '$selectedCount Seat(s): $seatCodesStr'
                        : 'कमाल ५ जागा निवडा (Select up to 5 seats)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${totalRupees.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: selectedCount == 0
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      );
                    },
              child: const Text(
                'पुढे चला (Proceed)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
