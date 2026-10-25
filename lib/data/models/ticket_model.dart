class TicketModel {
  final int id;
  final String ticketCode;
  final int orderId;
  final int sessionId;
  final int ticketTypeId;
  final int? seatId;
  final String seatCode;
  final String attendeeName;
  final int faceValue; // paise
  final String securityHash;
  final String qrPayload;
  final String status; // 'valid' | 'used' | 'cancelled'
  final DateTime createdAt;

  TicketModel({
    required this.id,
    required this.ticketCode,
    required this.orderId,
    required this.sessionId,
    required this.ticketTypeId,
    this.seatId,
    required this.seatCode,
    required this.attendeeName,
    required this.faceValue,
    required this.securityHash,
    required this.qrPayload,
    this.status = 'valid',
    required this.createdAt,
  });

  double get faceValueRupees => faceValue / 100.0;
  bool get isValid => status == 'valid';
  bool get isUsed => status == 'used';
  bool get isCancelled => status == 'cancelled';

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      ticketCode: json['ticket_code'] ?? '',
      orderId: json['order_id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      ticketTypeId: json['ticket_type_id'] ?? 0,
      seatId: json['seat_id'],
      seatCode: json['seat_code'] ?? 'GA',
      attendeeName: json['attendee_name'] ?? 'Guest',
      faceValue: json['face_value'] ?? 0,
      securityHash: json['security_hash'] ?? '',
      qrPayload: json['qr_payload'] ?? '',
      status: json['status'] ?? 'valid',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticket_code': ticketCode,
        'order_id': orderId,
        'session_id': sessionId,
        'ticket_type_id': ticketTypeId,
        'seat_id': seatId,
        'seat_code': seatCode,
        'attendee_name': attendeeName,
        'face_value': faceValue,
        'security_hash': securityHash,
        'qr_payload': qrPayload,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
