import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/models/event_model.dart';
import 'widgets/event_card.dart';
import 'event_detail_screen.dart';
import 'my_tickets_screen.dart';
import 'post_event_screen.dart';
import 'profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/organizer_console_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<NavigatorState> _exploreNavKey = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEvent(BuildContext context, EventModel event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final s = S(Provider.of<LocaleProvider>(context));

    // Nested Explore navigator keeps bottom tabs visible on event/seat screens.
    List<Widget> views = [
      Navigator(
        key: _exploreNavKey,
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => _buildExploreView(context),
          );
        },
      ),
      const MyTicketsScreen(),
    ];

    List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.explore_rounded),
        label: s.explore,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.confirmation_number_rounded),
        label: s.myTickets,
      ),
    ];

    if (auth.isSuperAdmin) {
      views.add(const AdminDashboardScreen());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.admin_panel_settings_rounded),
        label: s.adminHub,
      ));
    } else if (auth.isOrganizer) {
      views.add(const OrganizerConsoleScreen());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.business_center_rounded),
        label: s.producerHub,
      ));
    } else {
      views.add(const PostEventScreen());
      navItems.add(BottomNavigationBarItem(
        icon: const Icon(Icons.theater_comedy_rounded),
        label: s.partner,
      ));
    }

    views.add(const ProfileScreen());
    navItems.add(BottomNavigationBarItem(
      icon: const Icon(Icons.person_rounded),
      label: s.profile,
    ));

    final safeIndex = _currentNavIndex.clamp(0, views.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // Re-tapping Explore pops nested stack to home root (tabs stay visible).
          if (index == 0 && _currentNavIndex == 0) {
            _exploreNavKey.currentState?.popUntil((route) => route.isFirst);
          }
          setState(() => _currentNavIndex = index);
        },
        items: navItems,
      ),
    );
  }

  Widget _buildExploreView(BuildContext context) {
    final eventsProv = Provider.of<EventsProvider>(context);

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => eventsProv.loadEvents(),
        child: CustomScrollView(
          slivers: [
            // Top App Bar with Logo, Role Badge & City Picker
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildTopHeader(context, eventsProv),
                    const SizedBox(height: 12),
                    _buildSearchBar(eventsProv),
                  ],
                ),
              ),
            ),

            // Admin-driven home rails (home_sections) — horizontal cards + bilingual titles
            ..._buildAdminDrivenSections(context, eventsProv),

            // All shows grid header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All Shows in ${eventsProv.selectedCity}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${eventsProv.selectedCity} मधील सर्व नाटके व चित्रपट',
                          style: const TextStyle(fontSize: 12, color: AppColors.gold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${eventsProv.events.length} Shows',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Events Grid with ultra-modern BookMyShow card styling
            if (eventsProv.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (eventsProv.events.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.movie_filter_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No events found in this category',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          eventsProv.setCategory('all');
                          eventsProv.setSearchQuery('');
                          _searchController.clear();
                        },
                        child: const Text('सर्व शो दाखवा (Reset Filters)', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = eventsProv.events[index];
                      return _buildEventCard(context, event);
                    },
                    childCount: eventsProv.events.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, EventsProvider prov) {
    final auth = Provider.of<AuthProvider>(context);

    return Row(
      children: [
        // Brand logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(90),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'MahaTicket',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 0.8),
                  ),
                  child: const Text(
                    'महाटिकिट',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (auth.isSuperAdmin)
                  const Text('Admin Portal • ', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold))
                else if (auth.isOrganizer)
                  const Text('Producer Hub • ', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold)),
                const Text(
                  'Real-Time Ticket Booking',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // City Selector Dropdown Button
        InkWell(
          onTap: () => _showCityPicker(context, prov),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  prov.selectedCity,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(EventsProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => prov.setSearchQuery(val),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search Marathi Natak, Movies, Theatres...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    prov.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildCategoryPills(EventsProvider prov) {
    final categories = [
      {'id': 'all', 'label': 'All Shows', 'label_mr': 'सर्व'},
      {'id': 'plays', 'label': 'Plays', 'label_mr': 'नाटक'},
      {'id': 'movies', 'label': 'Movies', 'label_mr': 'चित्रपट'},
      {'id': 'music', 'label': 'Concerts', 'label_mr': 'संगीत मैफल'},
      {'id': 'cultural', 'label': 'Festivals', 'label_mr': 'महोत्सव'},
      {'id': 'comedy', 'label': 'Standup', 'label_mr': 'हास्य'},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = prov.selectedCategory == cat['id'];

          return GestureDetector(
            onTap: () => prov.setCategory(cat['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  children: [
                    Text(
                      cat['label_mr']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${cat['label']})',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.white.withAlpha(200) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAdminDrivenSections(BuildContext context, EventsProvider eventsProv) {
    final sections = eventsProv.homeSections;
    final orderedKeys = sections.isNotEmpty
        ? sections.map((s) => s.sectionKey).toList()
        : ['hero', 'trending', 'categories', 'today', 'drama', 'music', 'venues'];

    final slivers = <Widget>[];
    for (final key in orderedKeys) {
      if (!eventsProv.isSectionVisible(key)) continue;
      switch (key) {
        case 'hero':
        case 'promoted':
          final items = eventsProv.eventsForSection(key);
          if (items.isNotEmpty) {
            slivers.add(SliverToBoxAdapter(
              child: _buildFeaturedCarousel(
                context,
                items,
                title: eventsProv.sectionTitle(
                  key,
                  'Featured Shows',
                  'विशेष आकर्षण',
                  marathi: Provider.of<LocaleProvider>(context, listen: false).isMarathi,
                ),
              ),
            ));
          }
          break;
        case 'categories':
          slivers.add(SliverToBoxAdapter(child: _buildCategoryPills(eventsProv)));
          break;
        case 'trending':
        case 'today':
        case 'drama':
        case 'music':
          final items = eventsProv.eventsForSection(key);
          if (items.isNotEmpty) {
            slivers.add(SliverToBoxAdapter(
              child: _buildHorizontalEventRail(
                context,
                title: eventsProv.sectionTitle(
                  key,
                  key == 'trending' ? 'Top Trending' : key.toUpperCase(),
                  key == 'trending' ? 'ट्रेंडिंग प्रयोग' : key,
                  marathi: Provider.of<LocaleProvider>(context, listen: false).isMarathi,
                ),
                events: items,
                ranked: key == 'trending',
              ),
            ));
          }
          break;
        case 'venues':
          if (eventsProv.venues.isNotEmpty) {
            slivers.add(SliverToBoxAdapter(child: _buildVenuesRail(eventsProv)));
          }
          break;
        default:
          break;
      }
    }

    // Ensure categories appear if admin list omitted them but pills are useful
    if (!orderedKeys.contains('categories') && eventsProv.isSectionVisible('categories')) {
      slivers.insert(1, SliverToBoxAdapter(child: _buildCategoryPills(eventsProv)));
    }
    return slivers;
  }

  Widget _buildHorizontalEventRail(
    BuildContext context, {
    required String title,
    required List<EventModel> events,
    bool ranked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            children: [
              Icon(
                ranked ? Icons.local_fire_department : Icons.theaters_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ranked ? 190 : 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              if (ranked) {
                return GestureDetector(
                  onTap: () => _openEvent(context, ev),
                  child: Container(
                    width: 135,
                    margin: const EdgeInsets.only(right: 14),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 20,
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: ev.posterUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(color: AppColors.surfaceLight),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 6,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary.withAlpha(220),
                              shadows: const [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Container(
                width: 148,
                margin: const EdgeInsets.only(right: 12),
                child: EventCard(
                  event: ev,
                  compact: true,
                  onTap: () => _openEvent(context, ev),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVenuesRail(EventsProvider eventsProv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Text(
            eventsProv.sectionTitle(
              'venues',
              'Iconic Theatres',
              'प्रसिद्ध नाट्यगृहे',
              marathi: Provider.of<LocaleProvider>(context, listen: false).isMarathi,
            ),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: eventsProv.venues.length,
            itemBuilder: (context, index) {
              final v = eventsProv.venues[index];
              final name = (v['name_mr'] ?? v['name'] ?? 'Theatre').toString();
              final city = (v['city'] ?? '').toString();
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    Text(city, style: const TextStyle(color: AppColors.gold, fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCarousel(BuildContext context, List<EventModel> featured, {String? title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title ?? 'Featured Shows (विशेष आकर्षण)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${featured.length} Hits',
                style: const TextStyle(fontSize: 12, color: AppColors.gold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 195,
          child: PageView.builder(
            itemCount: featured.length,
            controller: PageController(viewportFraction: 0.90),
            itemBuilder: (context, index) {
              final event = featured[index];
              return GestureDetector(
                onTap: () => _openEvent(context, event),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: event.bannerUrl ?? event.posterUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(color: AppColors.surfaceLight),
                        ),
                        // Dark Vignette
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withAlpha(140),
                                Colors.black.withAlpha(220),
                              ],
                            ),
                          ),
                        ),
                        // Content overlay
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (event.tag != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          event.tag!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      event.displayTitle(
                                        marathi: Provider.of<LocaleProvider>(context, listen: false).isMarathi,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (event.displayVenue(
                                      marathi: Provider.of<LocaleProvider>(context, listen: false).isMarathi,
                                    ).isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${event.displayVenue(marathi: Provider.of<LocaleProvider>(context, listen: false).isMarathi)} • ${event.venueCity}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(100),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Book Now',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                    ),
                                    if (event.minPriceRupees != null)
                                      Text(
                                        'From ₹${event.minPriceRupees!.toInt()}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 9.5, color: Colors.white70),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return EventCard(
      event: event,
      onTap: () => _openEvent(context, event),
    );
  }


  void _showCityPicker(BuildContext context, EventsProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select City / जिल्हा निवडा',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              ...prov.availableCities.map((city) {
                final isSelected = prov.selectedCity == city;
                return ListTile(
                  leading: Icon(
                    Icons.location_city,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(
                    city,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    prov.setCity(city);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
