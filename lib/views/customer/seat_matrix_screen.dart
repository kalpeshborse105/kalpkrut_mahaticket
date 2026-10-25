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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event?.title ?? 'Seat Selection', style: const TextStyle(fontSize: 15)),
            Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          // 5-Minute Live Hold Timer Pill
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
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: booking.secondsLeft < 60 ? AppColors.error : AppColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.formattedTimeLeft,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: booking.secondsLeft < 60 ? AppColors.error : AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Conflict banner if any
          if (booking.conflictError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.error.withAlpha(200),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.conflictError!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Seat Legend
          _buildLegend(),

          // Interactive Zoomable Auditorium Layout
          Expanded(
            child: InteractiveViewer(
              minScale: 0.7,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(40),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Stage / Screen Curved Bar
                    _buildScreenArc(),
                    const SizedBox(height: 30),

                    // Tiers (Balcony, Stall, Box)
                    _buildTierSection(
                      context,
                      booking,
                      tierName: 'Balcony / बाल्कनी',
                      price: '₹300',
                      rows: ['A', 'B', 'C'],
                    ),
                    const SizedBox(height: 24),

                    _buildTierSection(
                      context,
                      booking,
                      tierName: 'Stall / स्टॉल',
                      price: '₹450',
                      rows: ['D', 'E', 'F', 'G'],
                    ),
                    const SizedBox(height: 24),

                    _buildTierSection(
                      context,
                      booking,
                      tierName: 'VIP Box / बैठक',
                      price: '₹650',
                      rows: ['H', 'J'],
                    ),
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem('Available', AppColors.seatAvailableBorder, false),
          _legendItem('Selected', AppColors.seatSelected, true),
          _legendItem('Held (Locked)', AppColors.seatHeld, true),
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
          width: 280,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.cyan.withAlpha(200),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(80)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withAlpha(150),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'CINEMA SCREEN / रंगमंच',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTierSection(
    BuildContext context,
    BookingProvider booking, {
    required String tierName,
    required String price,
    required List<String> rows,
  }) {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tierName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  price,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid of seats for this tier
        ...rows.map((rowLabel) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row Letter
                SizedBox(
                  width: 20,
                  child: Text(
                    rowLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Seat numbers 1 to 12
                ...List.generate(12, (index) {
                  final seatNumber = index + 1;
                  final seatCode = '$rowLabel${seatNumber.toString().padLeft(2, '0')}';
                  final seatId = (rowLabel.codeUnitAt(0) - 64) * 100 + seatNumber;

                  final virtualSeat = SeatModel(
                    id: seatId,
                    venueId: booking.selectedEvent?.venueId ?? 1,
                    sectionId: 1,
                    rowLabel: rowLabel,
                    seatNumber: seatNumber,
                    seatCode: seatCode,
                  );

                  return _buildSeatTile(booking, virtualSeat);
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSeatTile(BookingProvider booking, SeatModel seat) {
    // Check if selected by current user
    final isSelected = booking.selectedSeats.any((s) => s.id == seat.id);

    // Check inventory status
    final inv = booking.inventory.firstWhere(
      (i) => i.seatId == seat.id,
      orElse: () => SeatInventoryModel(
        id: 0,
        sessionId: booking.selectedSession?.id ?? 0,
        seatId: seat.id,
        ticketTypeId: 1,
        status: 'available',
      ),
    );

    final isBooked = inv.status == 'booked';
    final isHeldByOther = inv.status == 'held' &&
        !inv.isExpired &&
        inv.heldByUserId != booking.holdToken;

    Color seatColor = Colors.transparent;
    Color borderColor = AppColors.seatAvailableBorder;
    Widget? innerWidget;

    if (isSelected) {
      seatColor = AppColors.seatSelected;
      borderColor = AppColors.seatSelected;
      innerWidget = Text(
        '${seat.seatNumber}',
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
      );
    } else if (isBooked) {
      seatColor = AppColors.seatBooked;
      borderColor = AppColors.seatBooked;
      innerWidget = const Icon(Icons.close, size: 10, color: AppColors.textMuted);
    } else if (isHeldByOther) {
      seatColor = AppColors.seatHeld.withAlpha(60);
      borderColor = AppColors.seatHeld;
      innerWidget = const Icon(Icons.lock, size: 9, color: AppColors.seatHeld);
    } else {
      seatColor = Colors.transparent;
      borderColor = AppColors.seatAvailableBorder;
      innerWidget = Text(
        '${seat.seatNumber}',
        style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
      );
    }

    return GestureDetector(
      onTap: (isBooked || isHeldByOther)
          ? null
          : () => booking.toggleSeat(seat),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.seatSelected.withAlpha(160),
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
            color: Colors.black.withAlpha(180),
            blurRadius: 12,
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
                        : 'Select up to 5 seats',
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}
