import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import 'admin_event_management_screen.dart';
import 'admin_venues_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_home_sections_screen.dart';
import 'organizer_console_screen.dart';
import 'qr_gate_scanner_screen.dart';
import 'scraper_center_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final metrics = admin.metrics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('कंट्रोल हब (Admin & Organizer Hub)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('MahaTicket Master Operations Center', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => admin.loadMetrics(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => admin.loadMetrics(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.surfaceLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'महाटिकिट प्रशासन व ऑपरेशन्स केंद्र',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Control events, venues, real-time sales & REA scrapers',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Counters Grid
              const Text(
                'Live Platform Metrics (थेट आकडेवारी)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _buildKpiCard(
                    'Gross Revenue',
                    '₹${(metrics['totalRevenueRupees'] as double).toStringAsFixed(2)}',
                    Icons.currency_rupee,
                    AppColors.gold,
                  ),
                  _buildKpiCard(
                    'Tickets Sold',
                    '${metrics['totalTicketsSold']}',
                    Icons.confirmation_number_outlined,
                    AppColors.success,
                  ),
                  _buildKpiCard(
                    'Active Shows',
                    '${metrics['totalEvents']}',
                    Icons.theater_comedy,
                    AppColors.primary,
                  ),
                  _buildKpiCard(
                    'Gate Scans Today',
                    '${metrics['totalScansToday']}',
                    Icons.qr_code_scanner,
                    AppColors.cyan,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Management Tools Grid
              const Text(
                'व्यवस्थापन व नियंत्रणे (Management Tools)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              // 0. Home Sections CMS (TicketGhar parity)
              _buildToolCard(
                title: 'होम स्क्रीन सेक्शन्स (Home Sections)',
                subtitle: 'Hero, trending, categories titles, visibility & sort order for customer app',
                icon: Icons.view_agenda_rounded,
                color: AppColors.cyan,
                badgeText: 'CMS',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminHomeSectionsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 1. Events & Shows Management
              _buildToolCard(
                title: 'नाटके व कार्यक्रम व्यवस्थापन (Events & Shows)',
                subtitle: 'Add new natak, movies, schedule showtimes & seat pricing tiers',
                icon: Icons.theater_comedy,
                color: AppColors.primary,
                badgeText: 'SHOW SCHEDULER',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminEventManagementScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 2. Theatres & Venues Catalog
              _buildToolCard(
                title: 'नाट्यगृह व थिएटर्स (Venues & Theatres)',
                subtitle: 'Auditorium directory across Pune & Maharashtra, capacities & layout matrix',
                icon: Icons.location_city,
                color: AppColors.gold,
                badgeText: 'MAHARASHTRA VENUES',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminVenuesScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 3. Master Orders & Transactions
              _buildToolCard(
                title: 'मास्टर ऑर्डर्स व व्यवहार (Orders & Transactions)',
                subtitle: 'All customer bookings, Razorpay transaction IDs, status & tickets',
                icon: Icons.receipt_long,
                color: AppColors.neonGreen,
                badgeText: 'REAL-TIME SALES',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 4. Coupons & Discounts
              _buildToolCard(
                title: 'प्रोमो कोड व ऑफर्स (Coupons & Offers)',
                subtitle: 'Create festive promo codes, percentage discounts & usage limits',
                icon: Icons.discount,
                color: AppColors.cyan,
                badgeText: 'DISCOUNT ENGINE',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminCouponsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 5. Organizer Console & Settlements
              _buildToolCard(
                title: 'निर्माते व आयोजक कन्सोल (Organizer Console)',
                subtitle: 'Producer payout dashboard, 6% fee deduction & daily settlements ledger',
                icon: Icons.business_center,
                color: Colors.orangeAccent,
                badgeText: 'PRODUCER LEDGER',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrganizerConsoleScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 6. REA Scraper Control Center
              _buildToolCard(
                title: 'REA स्क्रॅपर नियंत्रण कक्ष (Scraper Console)',
                subtitle: 'Ingest events from BookMyShow, TicketKhidkee & TicketAlay in real-time',
                icon: Icons.sync,
                color: AppColors.primary,
                badgeText: 'MORLUTO/REA',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScraperCenterScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // 7. Gate Ticket Scanner
              _buildToolCard(
                title: 'गेट क्यूआर स्कॅनर (Gate Ticket Scanner)',
                subtitle: 'Validate digital passes, detect duplicates & prevent counterfeit re-entry',
                icon: Icons.qr_code_scanner_rounded,
                color: AppColors.success,
                badgeText: 'GATE PASS',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrGateScannerScreen()),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
