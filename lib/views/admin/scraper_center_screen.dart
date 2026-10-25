import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/events_provider.dart';

class ScraperCenterScreen extends StatefulWidget {
  const ScraperCenterScreen({super.key});

  @override
  State<ScraperCenterScreen> createState() => _ScraperCenterScreenState();
}

class _ScraperCenterScreenState extends State<ScraperCenterScreen> {
  String _selectedRegion = 'Pune';

  final List<Map<String, String>> _targets = [
    {
      'id': 'all',
      'title': 'Full Pipeline (All 3 Portals)',
      'subtitle': 'BookMyShow + TicketKhidkee + TicketAlay',
    },
    {
      'id': 'bms',
      'title': 'BookMyShow (BMS)',
      'subtitle': 'Movies, Marathi plays & multiplex showtimes',
    },
    {
      'id': 'khidkee',
      'title': 'TicketKhidkee',
      'subtitle': 'Authentic Marathi Natak & cultural auditoriums',
    },
    {
      'id': 'alay',
      'title': 'TicketAlay',
      'subtitle': 'Classical music fests, Vasantotsav & drama',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('REA Scraper Control Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Logs',
            onPressed: () => admin.clearLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.terminal, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reverse Engineer Anything (REA) Pipeline',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'github.com/morluto/rea • Live Web & API Ingestion',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Platform Target Dropdown
                Row(
                  children: [
                    const Text('Target: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: DropdownButton<String>(
                          value: admin.selectedScraperTarget,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: AppColors.surfaceLight,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: _targets.map((t) {
                            return DropdownMenuItem(
                              value: t['id'],
                              child: Text(t['title']!),
                            );
                          }).toList(),
                          onChanged: admin.isScraperRunning
                              ? null
                              : (val) {
                                  if (val != null) admin.setScraperTarget(val);
                                },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Region Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRegion,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: ['Pune', 'Mumbai', 'Nashik', 'Nagpur'].map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: admin.isScraperRunning
                            ? null
                            : (val) {
                                if (val != null) setState(() => _selectedRegion = val);
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Run Scraper Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: admin.isScraperRunning
                        ? null
                        : () async {
                            final count = await admin.runScraper(region: _selectedRegion);
                            if (context.mounted) {
                              Provider.of<EventsProvider>(context, listen: false).loadEvents();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.surfaceLight,
                                  content: Text(
                                    'Pipeline finished. $count events synchronized!',
                                    style: const TextStyle(color: AppColors.success),
                                  ),
                                ),
                              );
                            }
                          },
                    child: admin.isScraperRunning
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Scraping Live Catalog & Syncing Supabase...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 20),
                              SizedBox(width: 6),
                              Text('Execute REA Scraper Pipeline'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Live Terminal Output Console
          Expanded(
            child: Container(
              color: const Color(0xFF070B14),
              child: admin.scraperLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.terminal, size: 48, color: AppColors.textMuted.withAlpha(100)),
                          const SizedBox(height: 10),
                          const Text(
                            'Click "Execute REA Scraper Pipeline" above to run',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Live HTTP logs and database upsert statements will appear here.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: admin.scraperLogs.length,
                      itemBuilder: (context, index) {
                        final log = admin.scraperLogs[index];
                        final time = DateFormat('HH:mm:ss').format(log.timestamp);

                        Color levelColor = Colors.white;
                        if (log.level == 'INFO') levelColor = AppColors.cyan;
                        if (log.level == 'SUCCESS') levelColor = AppColors.success;
                        if (log.level == 'WARN') levelColor = AppColors.gold;
                        if (log.level == 'ERROR') levelColor = AppColors.error;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: '[$time] ',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                                TextSpan(
                                  text: '[${log.level}] ',
                                  style: TextStyle(
                                    color: levelColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: log.message,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
