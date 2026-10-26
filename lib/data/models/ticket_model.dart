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
    int asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    String asStr(dynamic a, dynamic b, [String fallback = '']) =>
        (a ?? b ?? fallback).toString();

    return TicketModel(
      id: asInt(json['id']),
      ticketCode: asStr(json['ticket_code'], json['ticketCode']),
      orderId: asInt(json['order_id'] ?? json['orderId']),
      sessionId: asInt(json['session_id'] ?? json['sessionId']),
      ticketTypeId: asInt(json['ticket_type_id'] ?? json['ticketTypeId']),
      seatId: json['seat_id'] ?? json['seatId'],
      seatCode: asStr(json['seat_code'], json['seatCode'], 'GA'),
      attendeeName: asStr(json['attendee_name'], json['attendeeName'], 'Guest'),
      faceValue: asInt(json['face_value'] ?? json['faceValue']),
      securityHash: asStr(json['security_hash'], json['securityHash']),
      qrPayload: asStr(json['qr_payload'], json['qrPayload']),
      status: asStr(json['status'], null, 'valid'),
      createdAt: DateTime.tryParse(
            asStr(json['created_at'], json['createdAt']),
          ) ??
          DateTime.now(),
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
