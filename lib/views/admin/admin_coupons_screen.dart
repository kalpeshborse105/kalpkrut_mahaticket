import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/supabase_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    final list = await _supabase.getCoupons();
    if (mounted) {
      setState(() {
        _coupons = list;
        _isLoading = false;
      });
    }
  }

  void _openAddCouponDialog() {
    final codeController = TextEditingController();
    final valueController = TextEditingController(text: '20');
    final minOrderController = TextEditingController(text: '400');
    final maxDiscountController = TextEditingController(text: '150');
    final limitController = TextEditingController(text: '500');
    String discountType = 'percentage';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.discount, color: AppColors.gold),
                            SizedBox(width: 8),
                            Text(
                              'नवीन प्रोमो कोड (Add Coupon)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Coupon Code (e.g. NATAK20)',
                        hintText: 'MAHATICKET50',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: discountType,
                            dropdownColor: AppColors.surfaceLight,
                            decoration: const InputDecoration(labelText: 'Discount Type'),
                            items: const [
                              DropdownMenuItem(value: 'percentage', child: Text('टक्केवारी (% Off)')),
                              DropdownMenuItem(value: 'flat', child: Text('निश्चित रक्कम (Flat ₹)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => discountType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: valueController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: discountType == 'percentage' ? 'Discount %' : 'Flat ₹ Amount',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minOrderController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Min Order Value (₹)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxDiscountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Max Cap (₹)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: limitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Usage Limit (कमाल वापर मर्यादा)',
                        hintText: 'e.g. 500',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final code = codeController.text.trim().toUpperCase();
                          if (code.isEmpty) return;

                          final discVal = int.tryParse(valueController.text.trim()) ?? 10;
                          final minVal = (int.tryParse(minOrderController.text.trim()) ?? 0) * 100; // paise
                          final maxDisc = (int.tryParse(maxDiscountController.text.trim()) ?? 100) * 100; // paise
                          final limit = int.tryParse(limitController.text.trim()) ?? 500;

                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await _supabase.createCoupon({
                            'code': code,
                            'discount_type': discountType,
                            'discount_value': discVal,
                            'min_order_value': minVal,
                            'max_discount': maxDisc,
                            'usage_limit': limit,
                            'active': 1,
                          });

                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          if (ok) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('कुपन $code यशस्वीरीत्या तयार केले!')),
                            );
                            _loadCoupons();
                          }
                        },
                        child: const Text('कुपन तयार करा (Save Coupon)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('प्रोमो व डिस्काउंट कुपन्स (Coupons)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Discounts, Offers & Festive Promos', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoupons,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('नवीन कुपन (Add Coupon)', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openAddCouponDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _coupons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.discount_outlined, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text('कोणतेही सक्रीय कुपन उपलब्ध नाही (No coupons found)', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _openAddCouponDialog,
                        child: const Text('पहिला प्रोमो कोड जोडा'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _coupons.length,
                  itemBuilder: (context, index) {
                    final c = _coupons[index];
                    final code = c['code'] ?? '';
                    final isPercent = c['discount_type'] == 'percentage';
                    final discValue = c['discount_value'] ?? 0;
                    final isActive = (c['active'] == 1 || c['active'] == true);
                    final minOrder = ((c['min_order_value'] ?? 0) / 100.0).round();
                    final maxDisc = ((c['max_discount'] ?? 0) / 100.0).round();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isActive ? AppColors.gold.withAlpha(80) : Colors.white10,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gold.withAlpha(60)),
                              ),
                              child: const Icon(Icons.confirmation_number_outlined, color: AppColors.gold, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white, letterSpacing: 1.1),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(30),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isPercent ? '$discValue% OFF' : '₹$discValue OFF',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Min order: ₹$minOrder • Max cap: ₹$maxDisc',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isActive,
                              activeThumbColor: AppColors.gold,
                              onChanged: (val) async {
                                final id = c['id'];
                                if (id is int) {
                                  await _supabase.toggleCouponActive(id, val);
                                  _loadCoupons();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
