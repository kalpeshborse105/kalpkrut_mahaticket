import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/supabase_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await _supabase.getAllOrders(status: _statusFilter);
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((o) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final orderNo = (o['order_number'] ?? '').toString().toLowerCase();
      final name = (o['user_name'] ?? '').toString().toLowerCase();
      final phone = (o['user_phone'] ?? '').toString();
      final email = (o['user_email'] ?? '').toString().toLowerCase();
      final eventTitle = (o['events']?['title'] ?? '').toString().toLowerCase();
      return orderNo.contains(query) ||
          name.contains(query) ||
          phone.contains(query) ||
          email.contains(query) ||
          eventTitle.contains(query);
    }).toList();
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final grandTotal = (order['grand_total'] ?? 0) / 100.0;
    final faceValue = (order['ticket_face_value_total'] ?? 0) / 100.0;
    final platformFee = (order['platform_fee_total'] ?? 0) / 100.0;
    final taxTotal = (order['tax_total'] ?? 0) / 100.0;
    final discount = (order['discount_total'] ?? 0) / 100.0;

    DateTime? createdAt;
    if (order['created_at'] != null) {
      createdAt = DateTime.tryParse(order['created_at']);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['order_number'] ?? 'ORD-UNKNOWN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        if (createdAt != null)
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a').format(createdAt),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                    _buildStatusBadge(order['order_status'] ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Event details
                const Text('कार्यक्रम तपशील (Event Info)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  order['events']?['title'] ?? 'Event #${order['event_id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
                if (order['events']?['title_mr'] != null)
                  Text(order['events']['title_mr'], style: const TextStyle(color: Colors.white70, fontSize: 13)),

                const SizedBox(height: 16),
                // Customer details
                const Text('ग्राहक माहिती (Customer Details)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(order['user_name'] ?? 'Guest User', style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(order['user_phone'] ?? 'N/A', style: const TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(order['user_email'] ?? 'N/A', style: const TextStyle(color: Colors.white)),
                  ],
                ),

                const SizedBox(height: 16),
                // Payment & Gateways
                const Text('पेमेंट माहिती (Payment & Gateway)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                Text('Razorpay Payment ID: ${order['razorpay_payment_id'] ?? 'Not captured'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Razorpay Order ID: ${order['razorpay_order_id'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Payment Status: ${order['payment_status'] ?? 'pending'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Financial Breakdown
                const Text('बिल तपशील (Bill Breakdown)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 8),
                _buildPriceRow('Ticket Face Value (${order['ticket_count']} tickets)', '₹${faceValue.toStringAsFixed(2)}'),
                _buildPriceRow('Platform Convenience Fee', '₹${platformFee.toStringAsFixed(2)}'),
                _buildPriceRow('Taxes & GST (18%)', '₹${taxTotal.toStringAsFixed(2)}'),
                if (discount > 0)
                  _buildPriceRow('Discount Applied', '-₹${discount.toStringAsFixed(2)}', isDiscount: true),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('एकूण रक्कम (Grand Total)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Text(
                      '₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? AppColors.neonGreen : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = AppColors.neonGreen.withAlpha(30);
        text = AppColors.neonGreen;
        label = 'CONFIRMED';
        break;
      case 'cancelled':
        bg = AppColors.primary.withAlpha(30);
        text = AppColors.primary;
        label = 'CANCELLED';
        break;
      default:
        bg = AppColors.gold.withAlpha(30);
        text = AppColors.gold;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withAlpha(100)),
      ),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ऑर्डर्स व बुकींग्ज (Master Orders)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Real-time Checkout Orders & Transactions', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by Order #, Name, Phone, Show...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('All Orders', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmed', 'confirmed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cancelled', 'cancelled'),
                  ],
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('No orders found matching criteria', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final o = list[index];
                          final grandTotal = (o['grand_total'] ?? 0) / 100.0;
                          DateTime? date;
                          if (o['created_at'] != null) {
                            date = DateTime.tryParse(o['created_at']);
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Colors.white10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showOrderDetails(o),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          o['order_number'] ?? 'ORD-UNKNOWN',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                        ),
                                        _buildStatusBadge(o['order_status'] ?? 'pending'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      o['events']?['title'] ?? 'Event #${o['event_id']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${o['user_name'] ?? 'User'} • ${o['user_phone'] ?? ''}',
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                        Text(
                                          '${o['ticket_count']} Tickets',
                                          style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (date != null)
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a').format(date),
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          )
                                        else
                                          const SizedBox(),
                                        Text(
                                          '₹${grandTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.gold),
                                        ),
                                      ],
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _loadOrders();
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
