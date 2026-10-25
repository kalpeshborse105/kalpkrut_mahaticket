class OrderModel {
  final int id;
  final String orderNumber;
  final int userId;
  final String userEmail;
  final String userPhone;
  final String userName;
  final int eventId;
  final int sessionId;
  final int ticketCount;
  final int ticketFaceValueTotal; // paise
  final int platformFeeTotal; // paise
  final int taxTotal; // paise
  final int discountTotal; // paise
  final int grandTotal; // paise
  final String paymentStatus; // 'pending' | 'captured' | 'failed'
  final String orderStatus; // 'pending' | 'confirmed' | 'cancelled'
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userEmail,
    required this.userPhone,
    required this.userName,
    required this.eventId,
    required this.sessionId,
    required this.ticketCount,
    required this.ticketFaceValueTotal,
    required this.platformFeeTotal,
    required this.taxTotal,
    this.discountTotal = 0,
    required this.grandTotal,
    this.paymentStatus = 'pending',
    this.orderStatus = 'pending',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    required this.createdAt,
  });

  double get grandTotalRupees => grandTotal / 100.0;
  double get faceValueRupees => ticketFaceValueTotal / 100.0;
  double get platformFeeRupees => platformFeeTotal / 100.0;
  double get taxRupees => taxTotal / 100.0;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      orderNumber: json['order_number'] ?? '',
      userId: json['user_id'] ?? 1,
      userEmail: json['user_email'] ?? '',
      userPhone: json['user_phone'] ?? '',
      userName: json['user_name'] ?? '',
      eventId: json['event_id'] ?? 0,
      sessionId: json['session_id'] ?? 0,
      ticketCount: json['ticket_count'] ?? 0,
      ticketFaceValueTotal: json['ticket_face_value_total'] ?? 0,
      platformFeeTotal: json['platform_fee_total'] ?? 0,
      taxTotal: json['tax_total'] ?? 0,
      discountTotal: json['discount_total'] ?? 0,
      grandTotal: json['grand_total'] ?? 0,
      paymentStatus: json['payment_status'] ?? 'pending',
      orderStatus: json['order_status'] ?? 'pending',
      razorpayOrderId: json['razorpay_order_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'user_id': userId,
        'user_email': userEmail,
        'user_phone': userPhone,
        'user_name': userName,
        'event_id': eventId,
        'session_id': sessionId,
        'ticket_count': ticketCount,
        'ticket_face_value_total': ticketFaceValueTotal,
        'platform_fee_total': platformFeeTotal,
        'tax_total': taxTotal,
        'discount_total': discountTotal,
        'grand_total': grandTotal,
        'payment_status': paymentStatus,
        'order_status': orderStatus,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'created_at': createdAt.toIso8601String(),
      };
}
