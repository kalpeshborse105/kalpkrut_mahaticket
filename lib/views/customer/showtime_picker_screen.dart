import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../providers/booking_provider.dart';
import 'seat_matrix_screen.dart';

class ShowtimePickerScreen extends StatefulWidget {
  final EventModel event;

  const ShowtimePickerScreen({super.key, required this.event});

  @override
  State<ShowtimePickerScreen> createState() => _ShowtimePickerScreenState();
}

class _ShowtimePickerScreenState extends State<ShowtimePickerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).initEvent(widget.event);
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.event.title, style: const TextStyle(fontSize: 16)),
            Text(
              '${widget.event.language} • ${widget.event.category.toUpperCase()}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: booking.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Horizontal Date Selector
                _buildDateSelector(),
                const Divider(height: 1),

                // Venue & Showtimes List
                Expanded(
                  child: booking.sessions.isEmpty
                      ? _buildNoShowtimesView()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildVenueCard(context, booking),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedDate.day == date.day &&
              _selectedDate.month == date.month &&
              _selectedDate.year == date.year;

          final dayName = DateFormat('EEE').format(date).toUpperCase();
          final dayNum = DateFormat('dd').format(date);
          final monthName = DateFormat('MMM').format(date);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 58,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, BookingProvider booking) {
    final venue = booking.selectedVenue;
    final venueName = venue?.name ?? 'Bal Gandharva Ranga Mandir';
    final venueNameMr = venue?.nameMr ?? 'बालगंधर्व रंगमंदिर, पुणे';
    final address = venue?.address ?? 'JM Road, Shivajinagar, Pune';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.theater_comedy_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      venueNameMr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          const Text(
            'Available Showtimes / प्रयोगाची वेळ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Showtimes grid / wrap
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: booking.sessions.map((session) {
              final timeStr = DateFormat('hh:mm a').format(session.sessionStartTime);

              return InkWell(
                onTap: () async {
                  await booking.selectSession(session);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SeatMatrixScreen(),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withAlpha(160)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoShowtimesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No upcoming showtimes scheduled',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back soon or explore other events',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
