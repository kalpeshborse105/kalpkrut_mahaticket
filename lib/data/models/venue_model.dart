class VenueModel {
  final int id;
  final String name;
  final String nameMr;
  final String city;
  final String address;
  final String? pincode;
  final String? facilities;
  final bool hasSeatLayout;
  final int totalCapacity;
  final String? layoutConfig;

  VenueModel({
    required this.id,
    required this.name,
    required this.nameMr,
    required this.city,
    required this.address,
    this.pincode,
    this.facilities,
    this.hasSeatLayout = true,
    this.totalCapacity = 500,
    this.layoutConfig,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] ?? '',
      nameMr: json['name_mr'] ?? json['name'] ?? '',
      city: json['city'] ?? 'Pune',
      address: json['address'] ?? '',
      pincode: json['pincode'],
      facilities: json['facilities'],
      hasSeatLayout: json['has_seat_layout'] == 1 || json['has_seat_layout'] == true,
      totalCapacity: json['total_capacity'] ?? 500,
      layoutConfig: json['layout_config'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_mr': nameMr,
        'city': city,
        'address': address,
        'pincode': pincode,
        'facilities': facilities,
        'has_seat_layout': hasSeatLayout ? 1 : 0,
        'total_capacity': totalCapacity,
        'layout_config': layoutConfig,
      };
}
