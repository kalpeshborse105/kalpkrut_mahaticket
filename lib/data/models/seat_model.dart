class SeatModel {
  final int id;
  final int venueId;
  final int sectionId;
  final String rowLabel;
  final int seatNumber;
  final String seatCode;
  final String tier; // 'platinum' | 'gold' | 'silver' | 'standard'
  final int isAccessible;
  final int isBlocked;

  SeatModel({
    required this.id,
    required this.venueId,
    required this.sectionId,
    required this.rowLabel,
    required this.seatNumber,
    required this.seatCode,
    this.tier = 'standard',
    this.isAccessible = 0,
    this.isBlocked = 0,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      venueId: json['venue_id'] ?? 0,
      sectionId: json['section_id'] ?? 0,
      rowLabel: json['row_label'] ?? '',
      seatNumber: json['seat_number'] ?? 0,
      seatCode: json['seat_code'] ?? '',
      tier: json['tier'] ?? 'standard',
      isAccessible: json['is_accessible'] ?? 0,
      isBlocked: json['is_blocked'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'venue_id': venueId,
        'section_id': sectionId,
        'row_label': rowLabel,
        'seat_number': seatNumber,
        'seat_code': seatCode,
        'tier': tier,
        'is_accessible': isAccessible,
        'is_blocked': isBlocked,
      };
}

class SeatInventoryModel {
  final int id;
  final int sessionId;
  final int seatId;
  final int ticketTypeId;
  final String status; // 'available' | 'held' | 'booked' | 'blocked'
  final String? heldByUserId;
  final DateTime? holdExpiresAt;
  final int? orderId;

  SeatInventoryModel({
    required this.id,
    required this.sessionId,
    required this.seatId,
    required this.ticketTypeId,
    required this.status,
    this.heldByUserId,
    this.holdExpiresAt,
    this.orderId,
  });

  bool get isExpired {
    if (status != 'held' || holdExpiresAt == null) return false;
    return DateTime.now().isAfter(holdExpiresAt!);
  }

  bool isHeldBy(String holdToken) {
    if (isExpired) return false;
    return status == 'held' && heldByUserId == holdToken;
  }

  bool isAvailableForUser(String holdToken) {
    if (status == 'available') return true;
    if (status == 'held' && isExpired) return true;
    if (status == 'held' && heldByUserId == holdToken) return true;
    return false;
  }

  factory SeatInventoryModel.fromJson(Map<String, dynamic> json) {
    return SeatInventoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      sessionId: json['session_id'] ?? 0,
      seatId: json['seat_id'] ?? 0,
      ticketTypeId: json['ticket_type_id'] ?? 0,
      status: json['status'] ?? 'available',
      heldByUserId: json['held_by_user_id'],
      holdExpiresAt: json['hold_expires_at'] != null
          ? DateTime.tryParse(json['hold_expires_at'])
          : null,
      orderId: json['order_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'seat_id': seatId,
        'ticket_type_id': ticketTypeId,
        'status': status,
        'held_by_user_id': heldByUserId,
        'hold_expires_at': holdExpiresAt?.toIso8601String(),
        'order_id': orderId,
      };
}

class TicketTypeModel {
  final int id;
  final int eventId;
  final int sessionId;
  final int? sectionId;
  final String name;
  final String nameMr;
  final int price; // in paise
  final int totalQuota;
  final int availableQuota;
  final int isSeated;

  TicketTypeModel({
    required this.id,
    required this.eventId,
    required this.sessionId,
    this.sectionId,
    required this.name,
    required this.nameMr,
    required this.price,
    this.totalQuota = 0,
    this.availableQuota = 0,
    this.isSeated = 1,
  });

  double get priceRupees => price / 100.0;

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      eventId: json['event_id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      sectionId: json['section_id'],
      name: json['name'] ?? '',
      nameMr: json['name_mr'] ?? json['name'] ?? '',
      price: json['price'] ?? 0,
      totalQuota: json['total_quota'] ?? 0,
      availableQuota: json['available_quota'] ?? 0,
      isSeated: json['is_seated'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'session_id': sessionId,
        'section_id': sectionId,
        'name': name,
        'name_mr': nameMr,
        'price': price,
        'total_quota': totalQuota,
        'available_quota': availableQuota,
        'is_seated': isSeated,
      };
}

class VenueSectionModel {
  final int id;
  final int venueId;
  final String name;
  final String nameMr;
  final int rowsCount;
  final int colsCount;
  final int basePrice;
  final int accessible;

  VenueSectionModel({
    required this.id,
    required this.venueId,
    required this.name,
    required this.nameMr,
    this.rowsCount = 0,
    this.colsCount = 0,
    this.basePrice = 0,
    this.accessible = 0,
  });

  double get basePriceRupees => basePrice / 100.0;

  factory VenueSectionModel.fromJson(Map<String, dynamic> json) {
    return VenueSectionModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      venueId: json['venue_id'] ?? 0,
      name: json['name'] ?? '',
      nameMr: json['name_mr'] ?? json['name'] ?? '',
      rowsCount: json['rows_count'] ?? 0,
      colsCount: json['cols_count'] ?? 0,
      basePrice: json['base_price'] ?? 0,
      accessible: json['accessible'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'venue_id': venueId,
        'name': name,
        'name_mr': nameMr,
        'rows_count': rowsCount,
        'cols_count': colsCount,
        'base_price': basePrice,
        'accessible': accessible,
      };
}
