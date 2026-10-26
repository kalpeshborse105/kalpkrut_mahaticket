import 'package:flutter_test/flutter_test.dart';
import 'package:kalpkrut_mahaticket/data/models/event_model.dart';
import 'package:kalpkrut_mahaticket/data/models/order_model.dart';
import 'package:kalpkrut_mahaticket/data/models/seat_model.dart';
import 'package:kalpkrut_mahaticket/data/models/ticket_model.dart';
import 'package:kalpkrut_mahaticket/data/models/venue_model.dart';

void main() {
  group('Data Models Serialization & Deserialization Tests', () {
    test('SeatModel serialization and deserialization', () {
      final json = {
        'id': 101,
        'venue_id': 5,
        'section_id': 2,
        'row_label': 'C',
        'seat_number': 14,
        'seat_code': 'C14',
        'tier': 'gold',
        'is_accessible': 1,
        'is_blocked': 0,
      };

      final seat = SeatModel.fromJson(json);
      expect(seat.id, 101);
      expect(seat.venueId, 5);
      expect(seat.rowLabel, 'C');
      expect(seat.seatNumber, 14);
      expect(seat.seatCode, 'C14');
      expect(seat.tier, 'gold');
      expect(seat.isAccessible, 1);
      expect(seat.isBlocked, 0);

      final exported = seat.toJson();
      expect(exported['id'], 101);
      expect(exported['seat_code'], 'C14');
    });

    test('VenueSectionModel serialization and price in Rupees', () {
      final json = {
        'id': 162,
        'venue_id': 1,
        'name': 'Premium',
        'name_mr': 'प्रीमियम',
        'rows_count': 4,
        'cols_count': 20,
        'base_price': 50000,
        'accessible': 1,
      };

      final section = VenueSectionModel.fromJson(json);
      expect(section.id, 162);
      expect(section.name, 'Premium');
      expect(section.nameMr, 'प्रीमियम');
      expect(section.basePrice, 50000);
      expect(section.basePriceRupees, 500.0);
    });

    test('SeatInventoryModel expiry and availability checks', () {
      final now = DateTime.now();
      final expiredTime = now.subtract(const Duration(minutes: 6));
      final activeTime = now.add(const Duration(minutes: 4));

      final activeInv = SeatInventoryModel(
        id: 1,
        sessionId: 10,
        seatId: 205,
        ticketTypeId: 2,
        status: 'held',
        heldByUserId: 'hold_user_abc',
        holdExpiresAt: activeTime,
      );

      expect(activeInv.isExpired, isFalse);
      expect(activeInv.isHeldBy('hold_user_abc'), isTrue);
      expect(activeInv.isHeldBy('hold_user_xyz'), isFalse);
      expect(activeInv.isAvailableForUser('hold_user_abc'), isTrue);
      expect(activeInv.isAvailableForUser('hold_user_xyz'), isFalse);

      final expiredInv = SeatInventoryModel(
        id: 2,
        sessionId: 10,
        seatId: 206,
        ticketTypeId: 2,
        status: 'held',
        heldByUserId: 'hold_user_abc',
        holdExpiresAt: expiredTime,
      );

      expect(expiredInv.isExpired, isTrue);
      // Expired hold becomes available to another customer
      expect(expiredInv.isAvailableForUser('hold_user_xyz'), isTrue);
    });

    test('TicketTypeModel price conversion to rupees', () {
      final tt = TicketTypeModel(
        id: 45,
        eventId: 12,
        sessionId: 3,
        name: 'VIP Balcony',
        nameMr: 'बाल्कनी',
        price: 65000, // 65000 paise = ₹650.00
      );

      expect(tt.priceRupees, 650.0);
    });

    test('OrderModel serialization and total calculation', () {
      final json = {
        'id': 78,
        'order_number': 'MHTK-2026-9A6401E',
        'user_id': 12,
        'user_email': 'attendee@mahaticket.in',
        'user_phone': '+91 9876543210',
        'user_name': 'Anand Patil',
        'event_id': 86,
        'session_id': 31,
        'ticket_count': 2,
        'ticket_face_value_total': 100000,
        'platform_fee_total': 6000,
        'tax_total': 1080,
        'discount_total': 5000,
        'grand_total': 102080,
        'payment_status': 'captured',
        'order_status': 'confirmed',
        'razorpay_payment_id': 'pay_123456789',
        'created_at': DateTime.now().toIso8601String(),
      };

      final order = OrderModel.fromJson(json);
      expect(order.orderNumber, 'MHTK-2026-9A6401E');
      expect(order.ticketCount, 2);
      expect(order.grandTotalRupees, 1020.80);
      expect(order.isConfirmed, isTrue);
    });

    test('TicketModel serialization and status check', () {
      final ticket = TicketModel(
        id: 180,
        ticketCode: 'TK-2026-7D9C346B',
        orderId: 91,
        sessionId: 1,
        ticketTypeId: 25,
        seatId: 2055,
        seatCode: 'A03',
        attendeeName: 'Sachin Tendulkar',
        faceValue: 50000,
        securityHash: '2597ec26433bba436aa33bbb2e204118aeca2836493166726e2b42f5d4d4f2e0',
        qrPayload: 'MTSEC:v1:TK-2026-7D9C346B:MHTK-2026-9A6401E:86:A03:2597ec26433bba43',
        status: 'valid',
        createdAt: DateTime.now(),
      );

      expect(ticket.isValid, isTrue);
      expect(ticket.isUsed, isFalse);
      expect(ticket.qrPayload.startsWith('MTSEC:v1:'), isTrue);
    });

    test('VenueModel serialization and layout configuration', () {
      final json = {
        'id': 7,
        'name': 'PVR INOX: R City Mall',
        'name_mr': 'पीव्हीआर आयनॉक्स: आर सिटी मॉल',
        'city': 'Mumbai',
        'address': 'LBS Marg, Ghatkopar West',
        'total_capacity': 600,
        'has_seat_layout': 1,
        'layout_config': '{"screenArc":true}',
      };

      final venue = VenueModel.fromJson(json);
      expect(venue.id, 7);
      expect(venue.name, 'PVR INOX: R City Mall');
      expect(venue.city, 'Mumbai');
      expect(venue.hasSeatLayout, isTrue);
      expect(venue.totalCapacity, 600);
    });

    test('EventModel serialization, venue attachment and min price in Rupees', () {
      final json = {
        'id': 86,
        'organizer_id': 1,
        'venue_id': 7,
        'title': 'Kantara: Chapter 1',
        'title_mr': 'कांतारा: चॅप्टर १',
        'slug': 'kantara-chapter-1',
        'category': 'movies',
        'category_mr': 'चित्रपट',
        'language': 'Marathi',
        'age_guidance': 'UA',
        'duration_minutes': 165,
        'description': 'Origin story',
        'description_mr': 'दैवी लोकगाथा',
        'poster_url': 'https://example.com/poster.jpg',
        'featured': 1,
        'min_price_paise': 18000,
        'venues': {
          'id': 7,
          'name': 'PVR INOX: R City Mall',
          'name_mr': 'पीव्हीआर आयनॉक्स',
          'city': 'Mumbai',
          'address': 'Ghatkopar West',
        },
      };

      final event = EventModel.fromJson(json);
      expect(event.id, 86);
      expect(event.title, 'Kantara: Chapter 1');
      expect(event.category, 'movies');
      expect(event.minPriceRupees, 180.0);
      expect(event.venue, isNotNull);
      expect(event.venueDisplayName, 'पीव्हीआर आयनॉक्स');
      expect(event.venueCity, 'Mumbai');
    });
  });
}

