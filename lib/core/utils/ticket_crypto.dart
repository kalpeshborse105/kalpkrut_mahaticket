import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/env_config.dart';

class TicketCrypto {
  /// Generates a HMAC-SHA256 signature for ticket verification
  static String generateSignature(String data) {
    final key = utf8.encode(EnvConfig.ticketSecret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// Builds a tamper-proof QR code payload for a digital ticket
  static String buildTicketQrPayload({
    required String ticketCode,
    required String orderNumber,
    required int sessionId,
    required String seatCode,
  }) {
    final rawData = '$ticketCode|$orderNumber|$sessionId|$seatCode';
    final sig = generateSignature(rawData);
    return 'MHTK|$rawData|$sig';
  }

  /// Validates a scanned QR payload
  static Map<String, dynamic>? verifyTicketQrPayload(String scannedPayload) {
    try {
      final parts = scannedPayload.split('|');
      if (parts.length != 6 || parts[0] != 'MHTK') {
        return null;
      }

      final ticketCode = parts[1];
      final orderNumber = parts[2];
      final sessionId = int.tryParse(parts[3]) ?? 0;
      final seatCode = parts[4];
      final receivedSig = parts[5];

      final rawData = '$ticketCode|$orderNumber|$sessionId|$seatCode';
      final expectedSig = generateSignature(rawData);

      final isValid = expectedSig == receivedSig;

      return {
        'isValid': isValid,
        'ticketCode': ticketCode,
        'orderNumber': orderNumber,
        'sessionId': sessionId,
        'seatCode': seatCode,
        'signature': receivedSig,
      };
    } catch (_) {
      return null;
    }
  }
}
