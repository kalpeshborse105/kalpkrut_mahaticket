import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/event_model.dart';
import '../../data/models/venue_model.dart';
import '../../data/services/supabase_service.dart';

class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() => _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState extends State<AdminEventManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<EventModel> _events = [];
  List<VenueModel> _venues = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final events = await _supabaseService.getEvents();
    final venues = await _supabaseService.getAllVenues();
    if (mounted) {
      setState(() {
        _events = events;
        _venues = venues;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'all'
        ? _events
        : _events.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Catalog & Showtimes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Show / नाटक जोडा', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddEventDialog(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Category Filter Tabs
                Container(
                  height: 48,
                  color: AppColors.surface,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    children: [
                      _filterChip('all', 'All Shows'),
                      _filterChip('plays', 'Plays (नाटके)'),
                      _filterChip('movies', 'Movies (चित्रपट)'),
                      _filterChip('music', 'Music (संगीत)'),
                      _filterChip('cultural', 'Cultural (महोत्सव)'),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Events List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No events found in this category'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final event = filtered[index];
                            final isPublished = event.status == 'published';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Poster
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      event.posterUrl,
                                      width: 60,
                                      height: 85,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(width: 60, height: 85, color: AppColors.surfaceLight),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                event.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isPublished
                                                    ? AppColors.success.withAlpha(30)
                                                    : AppColors.error.withAlpha(30),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isPublished ? AppColors.success : AppColors.error,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                isPublished ? 'PUBLISHED' : 'DRAFT',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPublished ? AppColors.success : AppColors.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          event.titleMr,
                                          style: const TextStyle(fontSize: 12, color: AppColors.gold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Category: ${event.category.toUpperCase()} • ${event.durationMinutes} mins',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 8),

                                        // Actions Row
                                        Row(
                                          children: [
                                            // Add Session Button
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                              icon: const Icon(Icons.calendar_month, size: 14),
                                              label: const Text('Add Showtime', style: TextStyle(fontSize: 11)),
                                              onPressed: () => _showAddSessionDialog(context, event),
                                            ),
                                            const SizedBox(width: 8),

                                            // Toggle Publish Status
                                            TextButton(
                                              onPressed: () async {
                                                final newStatus = isPublished ? 'draft' : 'published';
                                                await _supabaseService.toggleEventStatus(event.id, newStatus);
                                                _loadData();
                                              },
                                              child: Text(
                                                isPublished ? 'Unpublish' : 'Publish',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isPublished ? AppColors.error : AppColors.success,
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
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String id, String label) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceLight,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        onSelected: (_) => setState(() => _selectedCategory = id),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleEnController = TextEditingController();
    final titleMrController = TextEditingController();
    final descEnController = TextEditingController();
    final descMrController = TextEditingController();
    final posterController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?w=800',
    );
    final durationController = TextEditingController(text: '150');
    String selectedCategory = 'plays';
    int selectedVenueId = _venues.isNotEmpty ? _venues.first.id : 1;
    String tag = 'हाऊसफुल्ल';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Event / नवीन कार्यक्रम जोडा',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: titleEnController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Event Title (English)'),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: titleMrController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'कार्यक्रमाचे नाव (मराठी)'),
                    ),
                    const SizedBox(height: 10),

                    // Category & Venue Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            dropdownColor: AppColors.surfaceLight,
                            decoration: const InputDecoration(labelText: 'Category'),
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'plays', child: Text('Plays (नाटक)')),
                              DropdownMenuItem(value: 'movies', child: Text('Movies (चित्रपट)')),
                              DropdownMenuItem(value: 'music', child: Text('Music (संगीत)')),
                              DropdownMenuItem(value: 'cultural', child: Text('Cultural (महोत्सव)')),
                              DropdownMenuItem(value: 'comedy', child: Text('Comedy (हास्य)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedCategory = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedVenueId,
                            dropdownColor: AppColors.surfaceLight,
                            decoration: const InputDecoration(labelText: 'Venue / नाट्यगृह'),
                            style: const TextStyle(color: Colors.white),
                            items: _venues.map((v) {
                              return DropdownMenuItem(
                                value: v.id,
                                child: Text(v.name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedVenueId = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: posterController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Poster Image URL'),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: descEnController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Synopsis (English)'),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: descMrController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'नाट्य / चित्रपट परिचय (मराठी)'),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: const Text('Save & Publish Event'),
                        onPressed: () async {
                          final title = titleEnController.text.trim();
                          if (title.isEmpty) return;

                          final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

                          await _supabaseService.createEvent({
                            'organizer_id': 1,
                            'venue_id': selectedVenueId,
                            'title': title,
                            'title_mr': titleMrController.text.trim().isEmpty ? title : titleMrController.text.trim(),
                            'slug': slug,
                            'category': selectedCategory,
                            'category_mr': selectedCategory == 'plays' ? 'नाटक' : 'चित्रपट',
                            'language': 'मराठी',
                            'age_guidance': 'U',
                            'duration_minutes': int.tryParse(durationController.text) ?? 150,
                            'description': descEnController.text.trim(),
                            'description_mr': descMrController.text.trim(),
                            'poster_url': posterController.text.trim(),
                            'featured': 1,
                            'tag': tag,
                            'status': 'published',
                          });

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) _loadData();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSessionDialog(BuildContext context, EventModel event) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 30);
    final balconyPriceController = TextEditingController(text: '300');
    final stallPriceController = TextEditingController(text: '450');
    final boxPriceController = TextEditingController(text: '650');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final startDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
            final endDateTime = startDateTime.add(Duration(minutes: event.durationMinutes));

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text('Schedule Showtime for ${event.title}', style: const TextStyle(fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                      title: Text(DateFormat('EEE, d MMMM yyyy').format(selectedDate)),
                      trailing: const Text('Change', style: TextStyle(color: AppColors.primary)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setDialogState(() => selectedDate = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: AppColors.gold),
                      title: Text(selectedTime.format(dialogContext)),
                      trailing: const Text('Change', style: TextStyle(color: AppColors.gold)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );
                        if (picked != null) setDialogState(() => selectedTime = picked);
                      },
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const Text('Ticket Price Tiers (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: balconyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Balcony / बाल्कनी (₹)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: stallPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stall / स्टॉल (₹)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: boxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'VIP Box / बॉक्स (₹)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  child: const Text('Schedule Session'),
                  onPressed: () async {
                    final balconyPaise = (int.tryParse(balconyPriceController.text) ?? 300) * 100;
                    final stallPaise = (int.tryParse(stallPriceController.text) ?? 450) * 100;
                    final boxPaise = (int.tryParse(boxPriceController.text) ?? 650) * 100;

                    final messenger = ScaffoldMessenger.of(context);
                    await _supabaseService.addEventSession(
                      eventId: event.id,
                      start: startDateTime,
                      end: endDateTime,
                      priceTiers: [
                        {'name': 'Balcony / बाल्कनी', 'name_mr': 'बाल्कनी', 'price': balconyPaise},
                        {'name': 'Stall / स्टॉल', 'name_mr': 'स्टॉल', 'price': stallPaise},
                        {'name': 'VIP Box / बॉक्स', 'name_mr': 'बॉक्स', 'price': boxPaise},
                      ],
                    );

                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Showtime session scheduled successfully!')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
