class SessionModel {
  final int id;
  final int eventId;
  final DateTime sessionStartTime;
  final DateTime sessionEndTime;
  final String status;

  SessionModel({
    required this.id,
    required this.eventId,
    required this.sessionStartTime,
    required this.sessionEndTime,
    this.status = 'active',
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      eventId: json['event_id'] is int ? json['event_id'] : int.tryParse('${json['event_id']}') ?? 0,
      sessionStartTime: DateTime.tryParse(json['session_start_time'] ?? '') ?? DateTime.now(),
      sessionEndTime: DateTime.tryParse(json['session_end_time'] ?? '') ??
          DateTime.now().add(const Duration(hours: 2, minutes: 30)),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'session_start_time': sessionStartTime.toIso8601String(),
        'session_end_time': sessionEndTime.toIso8601String(),
        'status': status,
      };
}
