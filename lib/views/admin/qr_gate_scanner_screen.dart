import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ticket_crypto.dart';
import '../../data/services/supabase_service.dart';

class QrGateScannerScreen extends StatefulWidget {
  const QrGateScannerScreen({super.key});

  @override
  State<QrGateScannerScreen> createState() => _QrGateScannerScreenState();
}

class _QrGateScannerScreenState extends State<QrGateScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isVerifying = false;
  Map<String, dynamic>? _lastScanResult;
  String _selectedGate = 'Gate 1 (Main Entrance)';

  final List<String> _gates = [
    'Gate 1 (Main Entrance)',
    'Gate 2 (Balcony Entry)',
    'Gate 3 (VIP Box Corridor)',
    'Gate 4 (Stage Door / Artists)',
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyTicket(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _lastScanResult = null;
    });

    try {
      String ticketCode = input;

      // Check if it's a signed QR payload
      if (input.startsWith('MHTK|')) {
        final verified = TicketCrypto.verifyTicketQrPayload(input);
        if (verified == null || verified['isValid'] != true) {
          setState(() {
            _lastScanResult = {
              'success': false,
              'status': 'COUNTERFEIT',
              'message': 'Cryptographic verification failed: Tampered or invalid QR payload!',
            };
          });
          return;
        }
        ticketCode = verified['ticketCode'];
      }

      // Check with Supabase database
      final result = await _supabaseService.validateAndScanTicket(
        ticketCode: ticketCode,
        gateName: _selectedGate,
      );

      setState(() {
        _lastScanResult = result;
      });
    } catch (e) {
      setState(() {
        _lastScanResult = {
          'success': false,
          'status': 'ERROR',
          'message': 'Scanner service error: $e',
        };
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditorium Gate Validator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gate Selection dropdown
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room, color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  const Text('Active Gate:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedGate,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceLight,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: _gates.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGate = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scanner Input Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan or Enter Ticket Code',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'e.g. TK-2026-84920 or MHTK|...',
                            prefixIcon: Icon(Icons.qr_code, size: 20),
                          ),
                          onSubmitted: _verifyTicket,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        onPressed: _isVerifying ? null : () => _verifyTicket(_codeController.text),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Verify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Result Display Card
            if (_lastScanResult != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final res = _lastScanResult!;
    final isSuccess = res['success'] == true;
    final status = res['status'] ?? '';
    final message = res['message'] ?? '';
    final ticket = res['ticket'];

    final Color statusColor = isSuccess
        ? AppColors.success
        : (status == 'ALREADY_USED' ? AppColors.warning : AppColors.error);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: statusColor,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            isSuccess ? 'ACCESS GRANTED' : 'ENTRY REJECTED: $status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
          if (ticket != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendee Name:', style: TextStyle(color: AppColors.textMuted)),
                Text(ticket.attendeeName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seat Code:', style: TextStyle(color: AppColors.textMuted)),
                Text(ticket.seatCode, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ticket Code:', style: TextStyle(color: AppColors.textMuted)),
                Text(ticket.ticketCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
