import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/supabase_service.dart';

class OrganizerConsoleScreen extends StatefulWidget {
  const OrganizerConsoleScreen({super.key});

  @override
  State<OrganizerConsoleScreen> createState() => _OrganizerConsoleScreenState();
}

class _OrganizerConsoleScreenState extends State<OrganizerConsoleScreen> {
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _settlements = [];
  List<Map<String, dynamic>> _organizers = [];
  String _selectedOrganizerName = 'श्री चिंतामणी थिएटर्स, पुणे';
  int? _selectedOrganizerId;

  // Aggregate metrics
  final double _grossGMV = 184500.0;
  final double _platformCommission = 11070.0; // 6%
  final double _gatewayCost = 3690.0; // 2%
  final double _netPayable = 169740.0;
  final int _totalTicketsSold = 412;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orgs = await _supabase.getOrganizers();
    final sets = await _supabase.getSettlements(organizerId: _selectedOrganizerId);

    if (mounted) {
      setState(() {
        _organizers = orgs;
        _settlements = sets;
        _isLoading = false;
      });
    }
  }

  void _showOrganizerPicker() {
    if (_organizers.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'नाट्य संस्था निवडा (Select Producer)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
              const Divider(color: Colors.white12),
              ..._organizers.map((o) {
                final name = o['company_name'] ?? o['name'] ?? 'Organizer';
                final isSelected = _selectedOrganizerName == name;
                return ListTile(
                  leading: const Icon(Icons.business_center, color: AppColors.primary),
                  title: Text(name, style: TextStyle(color: isSelected ? AppColors.primary : Colors.white)),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    setState(() {
                      _selectedOrganizerName = name;
                      _selectedOrganizerId = o['id'] is int ? o['id'] : null;
                    });
                    Navigator.pop(ctx);
                    _loadData();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showRequestPayoutDialog() {
    final amountController = TextEditingController(text: _netPayable.toStringAsFixed(0));
    final bankController = TextEditingController(text: 'HDFC Bank - A/C **4582 (IFSC: HDFC0000180)');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.gold),
              SizedBox(width: 8),
              Text('पेआऊट विनंती (Request Payout)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('निव्वळ देय रक्कम बँक खात्यात वर्ग करा:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Beneficiary Bank Account'),
              ),
              const SizedBox(height: 8),
              const Text('NEFT / RTGS transfer processed within 24 bank working hours.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करा (Cancel)', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('पेआऊट विनंती यशस्वीरीत्या नोंदवली गेली! (Payout requested)')),
                );
              },
              child: const Text('विनंती पाठवा (Submit)'),
            ),
          ],
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
            Text('आयोजक कन्सोल (Organizer Console)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Theatrical Producer & Event Manager Hub', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organizer banner card
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _showOrganizerPicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.surface,
                            AppColors.surfaceLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business_center, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedOrganizerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'अधिकृत नाट्य निर्माते • Tap to Switch Producer',
                                  style: TextStyle(color: AppColors.neonGreen, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text('आर्थिक आढावा (Financial Summary)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 12),

                  // Financial KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'सकल विक्री (Gross GMV)',
                          '₹${_grossGMV.toStringAsFixed(0)}',
                          '$_totalTicketsSold tickets sold',
                          AppColors.gold,
                          Icons.currency_rupee,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'निव्वळ देय (Net Payout)',
                          '₹${_netPayable.toStringAsFixed(0)}',
                          'Ready to transfer',
                          AppColors.neonGreen,
                          Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'प्लॅटफॉर्म फी (6%)',
                          '₹${_platformCommission.toStringAsFixed(0)}',
                          'MahaTicket Service Fee',
                          AppColors.textSecondary,
                          Icons.pie_chart_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'गेटवे आकार (2%)',
                          '₹${_gatewayCost.toStringAsFixed(0)}',
                          'Razorpay Netbanking/UPI',
                          AppColors.textSecondary,
                          Icons.payment,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('पेआऊट खात्यात जमा करा (Withdraw Payout)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _showRequestPayoutDialog,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('सेटलमेंट इतिहास (Settlements Ledger)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Daily T+1', style: TextStyle(fontSize: 11, color: AppColors.gold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_settlements.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          const Text('मागील सर्व सेटलमेंट्स पूर्ण झाल्या आहेत', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Current batch of ₹${_netPayable.toStringAsFixed(0)} will settle on midnight cycle.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _settlements.length,
                      itemBuilder: (context, index) {
                        final s = _settlements[index];
                        final ref = s['settlement_reference'] ?? 'SET-2026';
                        final net = ((s['net_payable_to_organizer'] ?? 0) / 100.0).toStringAsFixed(2);
                        final status = s['status'] ?? 'settled';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceLight,
                              child: Icon(Icons.receipt, color: AppColors.primary),
                            ),
                            title: Text(ref, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text('Event: ${s['events']?['title'] ?? 'Natak Show'} • UTR: ${s['payout_utr'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('₹$net', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.neonGreen, fontSize: 15)),
                                Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
