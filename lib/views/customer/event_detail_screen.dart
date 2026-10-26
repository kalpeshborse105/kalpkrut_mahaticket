import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../data/models/session_model.dart';
import '../../data/models/venue_model.dart';
import '../../providers/booking_provider.dart';
import 'seat_matrix_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  DateTime? _selectedDate;
  SessionModel? _selectedSession;
  bool _descExpanded = false;
  bool _isReminderSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final booking = Provider.of<BookingProvider>(context, listen: false);
      booking.initEvent(widget.event).then((_) {
        if (!mounted) return;
        if (booking.sessions.isNotEmpty) {
          final firstSession = booking.sessions.first;
          setState(() {
            _selectedSession = firstSession;
            _selectedDate = DateTime(
              firstSession.sessionStartTime.year,
              firstSession.sessionStartTime.month,
              firstSession.sessionStartTime.day,
            );
          });
        }
      });
    });
  }

  /// Groups real sessions from the database by calendar date
  Map<DateTime, List<SessionModel>> _groupSessionsByDate(List<SessionModel> sessions) {
    final Map<DateTime, List<SessionModel>> map = {};
    for (final s in sessions) {
      final dateKey = DateTime(
        s.sessionStartTime.year,
        s.sessionStartTime.month,
        s.sessionStartTime.day,
      );
      map.putIfAbsent(dateKey, () => []).add(s);
    }
    // Sort sessions within each day chronologically
    for (final list in map.values) {
      list.sort((a, b) => a.sessionStartTime.compareTo(b.sessionStartTime));
    }
    return map;
  }

  void _openGoogleMaps(VenueModel? venue) async {
    final name = venue?.name ?? 'Auditorium';
    final address = venue?.address ?? 'Maharashtra';
    final query = Uri.encodeComponent('$name, $address');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for $name')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final event = widget.event;
    final venue = booking.selectedVenue ?? event.venue;

    final dateGroups = _groupSessionsByDate(booking.sessions);
    final List<DateTime> availableDates = dateGroups.keys.toList()..sort();

    // Sessions for currently selected date
    List<SessionModel> sessionsForDay = [];
    if (_selectedDate != null && dateGroups.containsKey(_selectedDate)) {
      sessionsForDay = dateGroups[_selectedDate]!;
    } else if (availableDates.isNotEmpty) {
      sessionsForDay = dateGroups[availableDates.first] ?? [];
    }

    final String displayCategory = event.categoryMr.isNotEmpty ? event.categoryMr : event.category;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // Hero Banner with Back, Share, and Reminder buttons
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(160),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(160),
                    child: IconButton(
                      icon: Icon(
                        _isReminderSet ? Icons.notifications_active : Icons.notifications_none,
                        color: _isReminderSet ? AppColors.gold : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _isReminderSet = !_isReminderSet);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Text(
                              _isReminderSet
                                  ? 'रिमांडर सेट झाला! 🔔 शो सुरू होण्यापूर्वी सूचना मिळेल.'
                                  : 'रिमांडर काढला.',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.black.withAlpha(160),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 19),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Text('Sharing "${event.title}"...'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: event.bannerUrl ?? event.posterUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            ),
                          ),
                          child: const Icon(Icons.theater_comedy, size: 50, color: AppColors.primary),
                        ),
                      ),
                      // Smooth gradient overlay into page background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withAlpha(90),
                              Colors.transparent,
                              AppColors.background.withAlpha(200),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Event Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag Badge if present
                      if (event.tag != null && event.tag!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(90),
                                blurRadius: 6,
                              ),
                            ],
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

                      // Titles
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.titleMr.isNotEmpty ? event.titleMr : event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Meta Chips Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetaChip(Icons.theater_comedy_rounded, displayCategory),
                          _buildMetaChip(Icons.language_rounded, event.language),
                          _buildMetaChip(Icons.timer_outlined, '${event.durationMinutes} मिनिटे'),
                          _buildMetaChip(Icons.star_rounded, '${event.rating}/10 (${event.votesCount} मते)', isHighlight: true),
                          _buildMetaChip(Icons.verified_user_outlined, event.ageGuidance),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: AppColors.surfaceBorder, height: 1),
                      const SizedBox(height: 16),

                      // 1. DATE SELECTOR (Completely Data-Driven from DB Sessions)
                      const Text(
                        'तारीख निवडा (Select Show Date)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (availableDates.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_available_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'आगामी प्रयोग • तारीख लवकरच',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'या कार्यक्रमाचे पुढील प्रयोग लवकरच जाहीर होतील.',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableDates.length,
                            itemBuilder: (context, index) {
                              final date = availableDates[index];
                              final isSelected = _selectedDate != null &&
                                  _selectedDate!.year == date.year &&
                                  _selectedDate!.month == date.month &&
                                  _selectedDate!.day == date.day;

                              final dayName = DateFormat('EEE').format(date).toUpperCase();
                              final dayNum = DateFormat('dd').format(date);
                              final monthName = DateFormat('MMM').format(date).toUpperCase();

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = date;
                                    final sessionsOnDay = dateGroups[date] ?? [];
                                    if (sessionsOnDay.isNotEmpty) {
                                      _selectedSession = sessionsOnDay.first;
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 60,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                                          )
                                        : null,
                                    color: isSelected ? null : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withAlpha(90),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        dayName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? Colors.white : AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dayNum,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? Colors.white : Colors.white,
                                        ),
                                      ),
                                      Text(
                                        monthName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white.withAlpha(220) : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 2. THEATRE & SHOWTIMES LISTING (Real venue & sessions)
                      if (availableDates.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'नाट्यगृह व वेळ (Theatres & Times)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.success.withAlpha(60), width: 0.5),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'M-Ticket Available',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTheatreAndShowtimesCard(context, venue, sessionsForDay),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.surfaceBorder, height: 1),
                        const SizedBox(height: 16),
                      ],

                      // 3. ABOUT THE SHOW / SYNOPSIS
                      const Text(
                        'कथानक व माहिती (About The Show)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Marathi Description
                      Text(
                        event.descriptionMr.isNotEmpty ? event.descriptionMr : event.description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                        maxLines: _descExpanded ? null : 3,
                        overflow: _descExpanded ? null : TextOverflow.ellipsis,
                      ),

                      // English Description if available
                      if (event.description.isNotEmpty && event.descriptionMr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: _descExpanded ? null : 2,
                          overflow: _descExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],

                      InkWell(
                        onTap: () => setState(() => _descExpanded = !_descExpanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _descExpanded ? 'कमी माहिती (Read Less) ↑' : 'अधिक माहिती (Read More) ↓',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 4. CAST & CREW
                      if (event.cast.isNotEmpty) ...[
                        const Text(
                          'कलाकार व दिग्दर्शक (Cast & Crew)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCastList(event.cast),
                        const SizedBox(height: 20),
                      ],

                      // 5. CANCELLATION & AUDITORIUM POLICY
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'प्रवेश व रद्द करण्याचे नियम (Entry Policy)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.cancellationPolicy != null
                                  ? '• रद्द करण्याचे धोरण: ${event.cancellationPolicy!}\n• तिकीट बुकिंगनंतर मोबाईलवरील डिजिटल QR कोड थेट प्रवेशद्वारावर स्कॅन करता येईल.'
                                  : '• प्रयोगाच्या वेळेच्या ३० मिनिटे आधी नाट्यगृहात उपस्थित रहावे.\n• मोबाईलवरील M-Ticket थेट स्कॅन करून प्रवेश मिळवता येईल.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom spacing for sticky bar (prevents content cutoff on Android)
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Sticky CTA Bar (Android First & SafeArea Protected)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(200),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Showtime & Venue Summary
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedSession != null
                                ? DateFormat('EEE, d MMM • hh:mm a').format(_selectedSession!.sessionStartTime)
                                : 'Select Showtime',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            venue != null
                                ? (venue.nameMr.isNotEmpty ? venue.nameMr : venue.name)
                                : (event.venueDisplayName.isNotEmpty ? event.venueDisplayName : 'Auditorium'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Primary Action Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
                            const SnackBar(
                              content: Text('कृपया प्रयोगाची तारीख व वेळ निवडा (Please choose a showtime)'),
                            ),
                          );
                        }
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_seat_rounded, size: 17),
                          SizedBox(width: 6),
                          Text(
                            'जागा निवडा (Select Seats)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
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

  Widget _buildTheatreAndShowtimesCard(
    BuildContext context,
    VenueModel? venue,
    List<SessionModel> sessions,
  ) {
    final venueName = venue != null
        ? (venue.nameMr.isNotEmpty ? venue.nameMr : venue.name)
        : (widget.event.venueDisplayName.isNotEmpty ? widget.event.venueDisplayName : 'Bal Gandharva Ranga Mandir');
    final address = venue?.address ?? 'Maharashtra';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
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
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.theater_comedy_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.directions_rounded, color: AppColors.primary, size: 22),
                tooltip: 'Google Maps दिशा',
                onPressed: () => _openGoogleMaps(venue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 12),

          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'या तारखेला प्रयोग उपलब्ध नाही. कृपया इतर तारीख निवडा.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
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
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.success.withAlpha(160),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSelected ? 'Selected' : 'Available',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
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
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        itemBuilder: (context, index) {
          final member = cast[index];
          final nameStr = member.nameMr.isNotEmpty ? member.nameMr : member.name;
          final roleStr = member.roleMr.isNotEmpty ? member.roleMr : member.role;
          final initials = nameStr.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join();

          return Container(
            width: 78,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withAlpha(35),
                  backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null || member.avatarUrl!.isEmpty
                      ? Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 5),
                Text(
                  nameStr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                if (roleStr.isNotEmpty)
                  Text(
                    roleStr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? AppColors.gold.withAlpha(120) : AppColors.surfaceBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isHighlight ? AppColors.gold : AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppColors.gold : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
