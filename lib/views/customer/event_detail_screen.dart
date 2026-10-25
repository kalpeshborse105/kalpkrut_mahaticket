import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../data/models/session_model.dart';
import '../../providers/booking_provider.dart';
import 'seat_matrix_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  SessionModel? _selectedSession;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = Provider.of<BookingProvider>(context, listen: false);
      booking.initEvent(widget.event).then((_) {
        if (booking.sessions.isNotEmpty) {
          setState(() {
            _selectedSession = booking.sessions.first;
            _selectedDate = _selectedSession!.sessionStartTime;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final event = widget.event;

    // Filter sessions matching selected calendar day
    final daySessions = booking.sessions.where((s) {
      return s.sessionStartTime.year == _selectedDate.year &&
          s.sessionStartTime.month == _selectedDate.month &&
          s.sessionStartTime.day == _selectedDate.day;
    }).toList();

    final sessionsToShow = daySessions.isNotEmpty ? daySessions : booking.sessions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Backdrop with Poster & Vignette
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sharing ${event.title}...')),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.bannerUrl ?? event.posterUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(color: AppColors.surface),
                      ),
                      // Gradient shadow
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.background.withAlpha(160),
                              AppColors.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Event details body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag if present
                      if (event.tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.tag!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Titles
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.titleMr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Meta Chips Row (Category, Duration, Language, Rating)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(Icons.theater_comedy, event.category.toUpperCase()),
                          _buildChip(Icons.language, event.language),
                          _buildChip(Icons.timer_outlined, '${event.durationMinutes} mins'),
                          _buildChip(Icons.star, '${event.rating}/10 (${event.votesCount} votes)', isRating: true),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.surfaceBorder),
                      const SizedBox(height: 16),

                      // 1. DATE SELECTOR (Horizontal Calendar)
                      const Text(
                        'तारीख निवडा (Select Date)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      _buildDateSelector(),

                      const SizedBox(height: 20),

                      // 2. THEATRE & SHOWTIMES LISTING (Direct Booking Workflow)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'नाट्यगृह व प्रयोगाची वेळ (Theatres & Showtimes)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('M-Ticket Ready', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTheatreAndShowtimesCard(context, booking, sessionsToShow),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.surfaceBorder),
                      const SizedBox(height: 16),

                      // Synopsis / About
                      const Text(
                        'कथानक व सारांश (About The Show)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.descriptionMr,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                        maxLines: _descExpanded ? null : 3,
                        overflow: _descExpanded ? null : TextOverflow.ellipsis,
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                          maxLines: _descExpanded ? null : 2,
                          overflow: _descExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                      InkWell(
                        onTap: () => setState(() => _descExpanded = !_descExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _descExpanded ? 'कमी वाचा (Read Less)' : 'अधिक वाचा (Read More) ↓',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Cast & Crew Row
                      if (event.cast.isNotEmpty) ...[
                        const Text(
                          'कलाकार व दिग्दर्शक (Cast & Crew)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        _buildCastList(event.cast),
                      ],

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom sticky "Book Seats" CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(180),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: AppColors.surfaceBorder),
                ),
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
                            _selectedSession != null
                                ? DateFormat('EEE, d MMM • hh:mm a').format(_selectedSession!.sessionStartTime)
                                : 'Select showtime above',
                            style: const TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.selectedVenue?.name ?? 'Bal Gandharva Ranga Mandir',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (_selectedSession != null) {
                          await booking.selectSession(_selectedSession!);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SeatMatrixScreen()),
                            );
                          }
                        } else if (booking.sessions.isNotEmpty) {
                          await booking.selectSession(booking.sessions.first);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SeatMatrixScreen()),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('कृपया उपलब्ध वेळ निवडा (Please choose a showtime)')),
                          );
                        }
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_seat_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Select Seats (जागा निवडा)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
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
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                  width: 1,
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

  Widget _buildTheatreAndShowtimesCard(
    BuildContext context,
    BookingProvider booking,
    List<SessionModel> sessions,
  ) {
    final venue = booking.selectedVenue;
    final venueName = venue?.name ?? 'Bal Gandharva Ranga Mandir';
    final venueNameMr = venue?.nameMr ?? 'बालगंधर्व रंगमंदिर, पुणे';
    final address = venue?.address ?? 'JM Road, Shivajinagar, Pune';

    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.theater_comedy, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      venueNameMr,
                      style: const TextStyle(fontSize: 12, color: AppColors.gold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 10),

          // Showtimes list buttons
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'या तारखेला प्रयोग उपलब्ध नाही. कृपया इतर तारीख निवडा.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sessions.map((session) {
                final isSelected = _selectedSession?.id == session.id;
                final timeStr = DateFormat('hh:mm a').format(session.sessionStartTime);

                return InkWell(
                  onTap: () {
                    setState(() => _selectedSession = session);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.success.withAlpha(180),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(80),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSelected ? 'Selected' : 'Available',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white70 : AppColors.textMuted,
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

  Widget _buildCastList(List<CastCrewMember> cast) {
    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        itemBuilder: (context, index) {
          final member = cast[index];
          final nameStr = member.name.isNotEmpty ? member.name : member.nameMr;
          final initials = nameStr.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join();

          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withAlpha(35),
                  backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                      ? Text(
                          initials.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                        )
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  nameStr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, {bool isRating = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isRating ? AppColors.gold : AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isRating ? FontWeight.bold : FontWeight.normal,
              color: isRating ? AppColors.gold : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
