import 'dart:convert';

class CastCrewMember {
  final String name;
  final String nameMr;
  final String role;
  final String roleMr;
  final String? avatarUrl;

  CastCrewMember({
    required this.name,
    required this.nameMr,
    required this.role,
    required this.roleMr,
    this.avatarUrl,
  });

  factory CastCrewMember.fromJson(Map<String, dynamic> json) {
    return CastCrewMember(
      name: json['name'] ?? '',
      nameMr: json['nameMr'] ?? json['name_mr'] ?? json['name'] ?? '',
      role: json['role'] ?? '',
      roleMr: json['roleMr'] ?? json['role_mr'] ?? json['role'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'nameMr': nameMr,
        'role': role,
        'roleMr': roleMr,
        'avatarUrl': avatarUrl,
      };
}

class EventModel {
  final int id;
  final int organizerId;
  final int venueId;
  final String title;
  final String titleMr;
  final String slug;
  final String category;
  final String categoryMr;
  final String language;
  final String ageGuidance;
  final int durationMinutes;
  final String description;
  final String descriptionMr;
  final String posterUrl;
  final String? bannerUrl;
  final String? trailerUrl;
  final int featured;
  final String? tag;
  final List<CastCrewMember> castCrew;
  final int convenienceFeeValue; // in paise
  final int gstPercent;
  final String status;

  EventModel({
    required this.id,
    required this.organizerId,
    required this.venueId,
    required this.title,
    required this.titleMr,
    required this.slug,
    required this.category,
    required this.categoryMr,
    this.language = 'Marathi',
    this.ageGuidance = 'U',
    this.durationMinutes = 150,
    required this.description,
    required this.descriptionMr,
    required this.posterUrl,
    this.bannerUrl,
    this.trailerUrl,
    this.featured = 0,
    this.tag,
    this.castCrew = const [],
    this.convenienceFeeValue = 3000,
    this.gstPercent = 18,
    this.status = 'published',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<CastCrewMember> castList = [];
    if (json['cast_crew'] != null) {
      try {
        dynamic parsed = json['cast_crew'];
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }
        if (parsed is List) {
          castList = parsed.map((e) => CastCrewMember.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    return EventModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      organizerId: json['organizer_id'] ?? 1,
      venueId: json['venue_id'] ?? 1,
      title: json['title'] ?? '',
      titleMr: json['title_mr'] ?? json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'plays',
      categoryMr: json['category_mr'] ?? 'नाटक',
      language: json['language'] ?? 'Marathi',
      ageGuidance: json['age_guidance'] ?? 'U',
      durationMinutes: json['duration_minutes'] ?? 150,
      description: json['description'] ?? '',
      descriptionMr: json['description_mr'] ?? json['description'] ?? '',
      posterUrl: json['poster_url'] ?? 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=1000',
      bannerUrl: json['banner_url'],
      trailerUrl: json['trailer_url'],
      featured: json['featured'] ?? 0,
      tag: json['tag'],
      castCrew: castList,
      convenienceFeeValue: json['convenience_fee_value'] ?? 3000,
      gstPercent: json['gst_percent'] ?? 18,
      status: json['status'] ?? 'published',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizer_id': organizerId,
        'venue_id': venueId,
        'title': title,
        'title_mr': titleMr,
        'slug': slug,
        'category': category,
        'category_mr': categoryMr,
        'language': language,
        'age_guidance': ageGuidance,
        'duration_minutes': durationMinutes,
        'description': description,
        'description_mr': descriptionMr,
        'poster_url': posterUrl,
        'banner_url': bannerUrl,
        'trailer_url': trailerUrl,
        'featured': featured,
        'tag': tag,
        'cast_crew': jsonEncode(castCrew.map((c) => c.toJson()).toList()),
        'status': status,
      };

  // Convenience getters for modern BookMyShow style UI
  double get rating => (featured > 0 ? 9.4 : 8.8);
  int get votesCount => (featured > 0 ? 14200 : 5600);
  List<CastCrewMember> get cast => castCrew;
}
