import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class QrGateScannerScreen extends StatefulWidget {
  const QrGateScannerScreen({super.key});

  @override
  State<QrGateScannerScreen> createState() => _QrGateScannerScreenState();
}

class _QrGateScannerScreenState extends State<QrGateScannerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final BackendApiService _api = BackendApiService();
  MobileScannerController? _cameraController;

  bool _isVerifying = false;
  bool _cameraEnabled = !kIsWeb;
  bool _requireScope = true;
  Map<String, dynamic>? _lastScanResult;
  String _selectedGate = 'Gate 1 (Main Entrance)';
  String? _lastScannedRaw;

  final List<String> _gates = [
    'Gate 1 (Main Entrance)',
    'Gate 2 (Balcony Entry)',
    'Gate 3 (VIP Box Corridor)',
    'Gate 4 (Stage Door / Artists)',
  ];

  @override
  void initState() {
    super.initState();
    if (_cameraEnabled) {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _verifyTicket(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _lastScanResult = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final booking = Provider.of<BookingProvider>(context, listen: false);
      final targetEventId = booking.selectedEvent?.id;
      final targetSessionId = booking.selectedSession?.id;

      // Prefer TicketGhar authoritative scanner (MTGRP decrypt + event/session match)
      try {
        final apiRes = await _api.verifyGateScan(
          ticketCodeOrPayload: input,
          gateName: _selectedGate,
          scannerUserId: auth.dbUserId,
          targetEventId: targetEventId,
          targetSessionId: targetSessionId,
          requireScope: _requireScope && targetEventId != null && targetSessionId != null,
        );

        final valid = apiRes['valid'] == true || apiRes['success'] == true;
        final scanResult = (apiRes['scanResult'] ?? apiRes['status'] ?? '').toString();
        final ticket = apiRes['ticket'] ?? apiRes['pass'] ?? apiRes;
        final seats = apiRes['seatCodes'] ??
            ticket['seats'] ??
            ticket['seat'] ??
            '';

        setState(() {
          _lastScanResult = {
            'success': valid,
            'status': scanResult.isNotEmpty ? scanResult : (valid ? 'SUCCESS' : 'REJECTED'),
            'message': apiRes['message']?.toString() ??
                (valid
                    ? 'Entry approved — seats, showtime and venue matched.'
                    : 'Scan rejected by server.'),
            'event': ticket['event'] ?? ticket['eventTitle'],
            'venue': ticket['venue'] ?? ticket['venueName'],
            'showtime': ticket['showtimeLabel'] ?? ticket['showtime'],
            'seats': seats is List ? seats.join(', ') : seats.toString(),
            'isGroup': apiRes['isGroup'] == true,
            'ticketCount': apiRes['totalSeats'] ?? apiRes['ticketCount'],
          };
        });
        return;
      } on BackendApiException catch (e) {
        // Fall through to RPC for plain ticket codes when API unreachable
        debugPrint('Scanner API failed, falling back to RPC: $e');
        if (input.startsWith('MTGRP:')) {
          setState(() {
            _lastScanResult = {
              'success': false,
              'status': 'API_REQUIRED',
              'message':
                  'Group QR (MTGRP) must be verified by MahaTicket server. Check API connectivity.\n${e.message}',
            };
          });
          return;
        }
      }

      // RPC fallback for plain TK- codes only
      String ticketCode = input;
      if (input.startsWith('MTSEC:v1:')) {
        final parts = input.split(':');
        if (parts.length >= 3) ticketCode = parts[2];
      }

      final result = await _supabaseService.validateAndScanTicket(
        ticketCode: ticketCode,
        gateName: _selectedGate,
        scannerUserId: auth.dbUserId,
      );

      setState(() {
        _lastScanResult = {
          'success': result['success'] == true,
          'status': result['status'] ?? '',
          'message': result['message'] ?? '',
          'seats': result['ticket']?.seatCode,
          'event': null,
          'venue': null,
          'showtime': null,
        };
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

  void _onDetect(BarcodeCapture capture) {
    if (_isVerifying) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    if (raw == _lastScannedRaw) return;
    _lastScannedRaw = raw;
    _codeController.text = raw;
    _verifyTicket(raw);
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);
    final scopedEvent = booking.selectedEvent?.title;
    final scopedSession = booking.selectedSession?.sessionStartTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditorium Gate Validator'),
        actions: [
          if (!kIsWeb)
            IconButton(
              tooltip: _cameraEnabled ? 'Hide camera' : 'Show camera',
              icon: Icon(_cameraEnabled ? Icons.videocam_off : Icons.qr_code_scanner),
              onPressed: () {
                setState(() {
                  _cameraEnabled = !_cameraEnabled;
                  if (_cameraEnabled && _cameraController == null) {
                    _cameraController = MobileScannerController(
                      detectionSpeed: DetectionSpeed.normal,
                      facing: CameraFacing.back,
                    );
                  }
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Show lock (event + session)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    scopedEvent != null && scopedSession != null
                        ? '$scopedEvent • ${scopedSession.toLocal()}'
                        : 'Open an event showtime first for strict venue/date/time match, or disable scope below.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require event/session match', style: TextStyle(color: Colors.white, fontSize: 13)),
                    value: _requireScope,
                    onChanged: (v) => setState(() => _requireScope = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                      items: _gates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGate = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_cameraEnabled && _cameraController != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: MobileScanner(controller: _cameraController, onDetect: _onDetect),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan 1 group QR (MTGRP) for up to 5 seats — server checks event, showtime, venue & seats.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
            ],
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
                  const Text('Scan or Enter Ticket / Group QR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'MTGRP:v1:… or MTSEC:v1:… or MT-TK-…',
                            prefixIcon: Icon(Icons.qr_code, size: 20),
                          ),
                          onSubmitted: _verifyTicket,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isVerifying ? null : () => _verifyTicket(_codeController.text),
                        child: _isVerifying
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Verify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
          Icon(isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined, color: statusColor, size: 54),
          const SizedBox(height: 12),
          Text(
            isSuccess ? 'ACCESS GRANTED' : 'ENTRY REJECTED: $status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white)),
          const SizedBox(height: 12),
          if (res['event'] != null) _metaRow('Event', '${res['event']}'),
          if (res['venue'] != null) _metaRow('Venue', '${res['venue']}'),
          if (res['showtime'] != null) _metaRow('Showtime', '${res['showtime']}'),
          if (res['seats'] != null && '${res['seats']}'.isNotEmpty) _metaRow('Seats', '${res['seats']}'),
          if (res['isGroup'] == true) _metaRow('Pass type', 'Group QR (${res['ticketCount'] ?? ''} seats)'),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(color: AppColors.textMuted)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
        ],
      ),
    );
  }
}
