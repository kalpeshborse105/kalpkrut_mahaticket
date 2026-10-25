class TicketCrypto {
  /// Validates and parses a scanned QR payload (supports MTSEC:v1 and legacy MHTK)
  static Map<String, dynamic>? verifyTicketQrPayload(String scannedPayload) {
    try {
      final trimmed = scannedPayload.trim();

      // 1. MTSEC:v1 payload format: MTSEC:v1:<ticket_code>:<order_number>:<event_id>:<seat_code>:<security_hash>
      if (trimmed.startsWith('MTSEC:v1:')) {
        final parts = trimmed.split(':');
        if (parts.length >= 7) {
          return {
            'isValid': true,
            'ticketCode': parts[2],
            'orderNumber': parts[3],
            'eventId': int.tryParse(parts[4]) ?? 0,
            'seatCode': parts[5],
            'signature': parts[6],
          };
        } else if (parts.length >= 3) {
          return {
            'isValid': true,
            'ticketCode': parts[2],
          };
        }
      }

      // 2. Legacy MHTK pipe-delimited format: MHTK|<ticket_code>|<order_number>|<session_id>|<seat_code>|<signature>
      if (trimmed.startsWith('MHTK|')) {
        final parts = trimmed.split('|');
        if (parts.length >= 6) {
          return {
            'isValid': true,
            'ticketCode': parts[1],
            'orderNumber': parts[2],
            'sessionId': int.tryParse(parts[3]) ?? 0,
            'seatCode': parts[4],
            'signature': parts[5],
          };
        }
      }

      // 3. Plain Ticket Code format (e.g. TK-2026-XXXX)
      if (trimmed.startsWith('TK-')) {
        return {
          'isValid': true,
          'ticketCode': trimmed,
        };
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
