import 'package:flutter_test/flutter_test.dart';
import 'package:kalpkrut_mahaticket/core/utils/ticket_crypto.dart';

void main() {
  group('Digital Ticket QR Verification Tests', () {
    test('Parses signed MTSEC:v1 QR payload correctly', () {
      const payload = 'MTSEC:v1:TK-2026-991D8A75:MHTK-2026-4359C7A:86:B10:b866a0b6f0b0eb59';
      final result = TicketCrypto.verifyTicketQrPayload(payload);

      expect(result, isNotNull);
      expect(result!['isValid'], isTrue);
      expect(result['ticketCode'], 'TK-2026-991D8A75');
      expect(result['orderNumber'], 'MHTK-2026-4359C7A');
      expect(result['eventId'], 86);
      expect(result['seatCode'], 'B10');
      expect(result['signature'], 'b866a0b6f0b0eb59');
    });

    test('Parses legacy pipe-delimited MHTK payload', () {
      const payload = 'MHTK|TK-2026-ABC1234|MHTK-2026-ORD1|31|C14|SIG123';
      final result = TicketCrypto.verifyTicketQrPayload(payload);

      expect(result, isNotNull);
      expect(result!['isValid'], isTrue);
      expect(result['ticketCode'], 'TK-2026-ABC1234');
      expect(result['orderNumber'], 'MHTK-2026-ORD1');
      expect(result['sessionId'], 31);
      expect(result['seatCode'], 'C14');
    });

    test('Parses plain Ticket Code string', () {
      const payload = 'TK-2026-4904D698';
      final result = TicketCrypto.verifyTicketQrPayload(payload);

      expect(result, isNotNull);
      expect(result!['isValid'], isTrue);
      expect(result['ticketCode'], 'TK-2026-4904D698');
    });

    test('Rejects malformed or counterfeit QR string', () {
      const invalidPayload = 'RANDOM_QR_CODE_NOT_A_TICKET';
      final result = TicketCrypto.verifyTicketQrPayload(invalidPayload);

      expect(result, isNull);
    });
  });
}
