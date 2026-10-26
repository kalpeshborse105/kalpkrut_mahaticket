import 'dart:convert';
import 'venue_model.dart';

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
  final List<String> galleryUrls;
  final int featured;
  final String? tag;
  final List<CastCrewMember> castCrew;
  final int convenienceFeeValue; // in paise
  final int gstPercent;
  final String status;
  final VenueModel? venue;
  final int? minPricePaise;
  final String? cancellationPolicy;

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
    this.galleryUrls = const [],
    this.featured = 0,
    this.tag,
    this.castCrew = const [],
    this.convenienceFeeValue = 3000,
    this.gstPercent = 18,
    this.status = 'published',
    this.venue,
    this.minPricePaise,
    this.cancellationPolicy,
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

    List<String> gallery = [];
    if (json['gallery_urls'] != null) {
      try {
        dynamic parsed = json['gallery_urls'];
        if (parsed is String) {
          parsed = jsonDecode(parsed);
        }
        if (parsed is List) {
          gallery = parsed.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
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
      galleryUrls: gallery,
      featured: json['featured'] ?? 0,
      tag: json['tag'],
      castCrew: castList,
      convenienceFeeValue: json['convenience_fee_value'] ?? 3000,
      gstPercent: json['gst_percent'] ?? 18,
      status: json['status'] ?? 'published',
      venue: json['venues'] != null && json['venues'] is Map<String, dynamic>
          ? VenueModel.fromJson(json['venues'])
          : null,
      minPricePaise: json['min_price_paise'] is int
          ? json['min_price_paise']
          : int.tryParse('${json['min_price_paise']}'),
      cancellationPolicy: json['cancellation_policy'],
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
        'min_price_paise': minPricePaise,
        'cancellation_policy': cancellationPolicy,
      };

  // Convenience getters for modern BookMyShow style UI
  double get rating => (featured > 0 ? 9.4 : 8.8);
  int get votesCount => (featured > 0 ? 14200 : 5600);
  List<CastCrewMember> get cast => castCrew;
  double? get minPriceRupees => minPricePaise != null ? minPricePaise! / 100.0 : null;
  String get venueDisplayName =>
      venue != null ? (venue!.nameMr.isNotEmpty ? venue!.nameMr : venue!.name) : '';
  String get venueCity => venue?.city ?? 'Maharashtra';

  /// Single-language title (never EN+MR together).
  String displayTitle({required bool marathi}) {
    if (marathi) {
      return titleMr.trim().isNotEmpty ? titleMr : title;
    }
    return title.trim().isNotEmpty ? title : titleMr;
  }

  String displayDescription({required bool marathi}) {
    if (marathi) {
      return descriptionMr.trim().isNotEmpty ? descriptionMr : description;
    }
    return description.trim().isNotEmpty ? description : descriptionMr;
  }

  String displayCategory({required bool marathi}) {
    if (marathi) {
      return categoryMr.trim().isNotEmpty ? categoryMr : category;
    }
    return category.trim().isNotEmpty ? category : categoryMr;
  }

  String displayVenue({required bool marathi}) {
    if (venue == null) return '';
    if (marathi) {
      return venue!.nameMr.trim().isNotEmpty ? venue!.nameMr : venue!.name;
    }
    return venue!.name.trim().isNotEmpty ? venue!.name : venue!.nameMr;
  }
}

