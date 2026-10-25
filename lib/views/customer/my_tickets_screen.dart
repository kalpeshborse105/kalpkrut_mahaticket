import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/supabase_service.dart';
import '../../data/models/order_model.dart';
import 'ticket_view_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final String _userEmail = 'kalpeshborse105@gmail.com';
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final results = await _supabaseService.getUserBookings(_userEmail);
    if (mounted) {
      setState(() {
        _bookings = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital M-Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _bookings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final item = _bookings[index];
                      final order = OrderModel.fromJson(item);
                      final event = item['events'];
                      final title = event != null ? (event['title'] ?? 'Event') : 'Live Show';
                      final titleMr = event != null ? (event['title_mr'] ?? '') : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.confirmation_number, color: AppColors.primary),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (titleMr.isNotEmpty)
                                Text(titleMr, style: const TextStyle(fontSize: 12, color: AppColors.gold)),
                              const SizedBox(height: 4),
                              Text(
                                'Order #${order.orderNumber} • ${order.ticketCount} Tickets',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              Text(
                                'Total Paid: ₹${order.grandTotalRupees.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                          onTap: () async {
                            final tickets = await _supabaseService.getTicketsByOrderId(order.id);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketViewScreen(order: order, tickets: tickets),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No bookings found',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore upcoming Marathi plays and movies to book tickets',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
