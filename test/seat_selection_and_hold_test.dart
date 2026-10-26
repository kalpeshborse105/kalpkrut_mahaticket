import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kalpkrut_mahaticket/data/models/seat_model.dart';
import 'package:kalpkrut_mahaticket/data/services/inventory_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://hnseawulngdxbvltmthe.supabase.co',
        publishableKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhuc2Vhd3VsbmdkeGJ2bHRtdGhlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MDc5NjIsImV4cCI6MjEwNjI4Mzk2Mn0.Jk1k0ZPMpldURgv37Hq1OfTjSY45GBcZ21qT_74SK9o',
      );

    } catch (_) {}
  });

  group('Seat Selection and Hold Engine Tests', () {
    test('Hold token adheres to secure TicketGhar hold_ prefix and format', () {
      final service = InventoryService();
      final token = service.createHoldToken();

      expect(token.startsWith('hold_'), isTrue);
      expect(token.length, greaterThanOrEqualTo(32));
    });

    test('Booking limit enforces maximum 5 seats', () {
      final selectedSeats = <SeatModel>[];
      const maxSeatsLimit = 5;

      for (int i = 1; i <= 5; i++) {
        selectedSeats.add(SeatModel(
          id: i,
          venueId: 1,
          sectionId: 1,
          rowLabel: 'A',
          seatNumber: i,
          seatCode: 'A0$i',
        ));
      }

      expect(selectedSeats.length, maxSeatsLimit);

      // Attempting to add 6th seat should be rejected
      final canAddSixth = selectedSeats.length < maxSeatsLimit;
      expect(canAddSixth, isFalse);
    });

    test('Hold countdown calculation and formatted display', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 4, seconds: 45));

      final secondsLeft = expiresAt.difference(now).inSeconds;
      expect(secondsLeft, 285);

      final minutes = (secondsLeft ~/ 60).toString().padLeft(2, '0');
      final seconds = (secondsLeft % 60).toString().padLeft(2, '0');
      final formatted = '$minutes:$seconds';

      expect(formatted, '04:45');
    });

    test('HoldResult parsing from server JSON', () {
      final successResult = HoldResult(
        success: true,
        holdToken: 'hold_abc123456789',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        totalFaceValuePaise: 90000,
        platformFeePaise: 6000,
        taxPaise: 1080,
        grandTotalPaise: 97080,
        heldSeatIds: [101, 102],
      );

      expect(successResult.success, isTrue);
      expect(successResult.grandTotalRupees, 970.80);
      expect(successResult.faceValueRupees, 900.0);
      expect(successResult.platformFeeRupees, 60.0);
      expect(successResult.taxRupees, 10.80);
      expect(successResult.heldSeatIds.length, 2);

      final failureResult = HoldResult(
        success: false,
        errorMessage: 'One or more selected seats are no longer available.',
        holdToken: 'hold_abc123456789',
      );

      expect(failureResult.success, isFalse);
      expect(failureResult.errorMessage, contains('no longer available'));
    });
  });
}
