class HomeSectionModel {
  final int id;
  final String sectionKey;
  final String titleEn;
  final String titleMr;
  final String subtitleEn;
  final String subtitleMr;
  final String badgeEn;
  final String badgeMr;
  final int sortOrder;
  final bool isVisible;

  const HomeSectionModel({
    required this.id,
    required this.sectionKey,
    required this.titleEn,
    required this.titleMr,
    this.subtitleEn = '',
    this.subtitleMr = '',
    this.badgeEn = '',
    this.badgeMr = '',
    this.sortOrder = 0,
    this.isVisible = true,
  });

  /// Prefer Marathi when [marathi] is true — never concatenate both.
  String localizedTitle({required bool marathi}) {
    if (marathi) {
      return titleMr.trim().isNotEmpty ? titleMr : titleEn;
    }
    return titleEn.trim().isNotEmpty ? titleEn : titleMr;
  }

  String localizedSubtitle({required bool marathi}) {
    if (marathi) {
      return subtitleMr.trim().isNotEmpty ? subtitleMr : subtitleEn;
    }
    return subtitleEn.trim().isNotEmpty ? subtitleEn : subtitleMr;
  }

  String localizedBadge({required bool marathi}) {
    if (marathi) {
      return badgeMr.trim().isNotEmpty ? badgeMr : badgeEn;
    }
    return badgeEn.trim().isNotEmpty ? badgeEn : badgeMr;
  }

  @Deprecated('Use localizedTitle(marathi:)')
  String get title => localizedTitle(marathi: true);
  @Deprecated('Use localizedSubtitle(marathi:)')
  String get subtitle => localizedSubtitle(marathi: true);
  @Deprecated('Use localizedBadge(marathi:)')
  String get badge => localizedBadge(marathi: true);

  factory HomeSectionModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, [int d = 0]) => v is int ? v : int.tryParse('$v') ?? d;
    return HomeSectionModel(
      id: asInt(json['id']),
      sectionKey: (json['section_key'] ?? json['sectionKey'] ?? '').toString(),
      titleEn: (json['title_en'] ?? json['titleEn'] ?? '').toString(),
      titleMr: (json['title_mr'] ?? json['titleMr'] ?? '').toString(),
      subtitleEn: (json['subtitle_en'] ?? json['subtitleEn'] ?? '').toString(),
      subtitleMr: (json['subtitle_mr'] ?? json['subtitleMr'] ?? '').toString(),
      badgeEn: (json['badge_en'] ?? json['badgeEn'] ?? '').toString(),
      badgeMr: (json['badge_mr'] ?? json['badgeMr'] ?? '').toString(),
      sortOrder: asInt(json['sort_order'] ?? json['sortOrder']),
      isVisible: asInt(json['is_visible'] ?? json['isVisible'], 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section_key': sectionKey,
        'title_en': titleEn,
        'title_mr': titleMr,
        'subtitle_en': subtitleEn,
        'subtitle_mr': subtitleMr,
        'badge_en': badgeEn,
        'badge_mr': badgeMr,
        'sort_order': sortOrder,
        'is_visible': isVisible ? 1 : 0,
      };

  HomeSectionModel copyWith({
    String? titleEn,
    String? titleMr,
    String? subtitleEn,
    String? subtitleMr,
    String? badgeEn,
    String? badgeMr,
    int? sortOrder,
    bool? isVisible,
  }) {
    return HomeSectionModel(
      id: id,
      sectionKey: sectionKey,
      titleEn: titleEn ?? this.titleEn,
      titleMr: titleMr ?? this.titleMr,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      subtitleMr: subtitleMr ?? this.subtitleMr,
      badgeEn: badgeEn ?? this.badgeEn,
      badgeMr: badgeMr ?? this.badgeMr,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class EventReviewModel {
  final int id;
  final int eventId;
  final String userName;
  final String userEmail;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const EventReviewModel({
    required this.id,
    required this.eventId,
    required this.userName,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory EventReviewModel.fromJson(Map<String, dynamic> json) {
    return EventReviewModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      eventId: json['event_id'] is int
          ? json['event_id'] as int
          : int.tryParse('${json['event_id']}') ?? 0,
      userName: (json['user_name'] ?? 'Guest').toString(),
      userEmail: (json['user_email'] ?? '').toString(),
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 5,
      comment: (json['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}
