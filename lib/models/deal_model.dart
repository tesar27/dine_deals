class Deal {
  final int id;
  final String title;
  final String? description;
  final int restaurantId;
  final double? discountPercentage;
  final DateTime? validUntil;
  final bool? isActive;

  Deal({
    required this.id,
    required this.title,
    this.description,
    required this.restaurantId,
    this.discountPercentage,
    this.validUntil,
    this.isActive,
  });

  factory Deal.fromMap(Map<String, dynamic> map) {
    return Deal(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? '') ?? 0,
      title: map['title']?.toString() ?? map['name']?.toString() ?? 'Special Offer',
      description: map['description']?.toString(),
      restaurantId: map['restaurant_id'] is int ? map['restaurant_id'] as int : int.tryParse(map['restaurant_id']?.toString() ?? '') ?? 0,
      discountPercentage: map['discount_percentage'] != null ? double.tryParse(map['discount_percentage'].toString()) : null,
      validUntil: map['valid_until'] != null ? DateTime.tryParse(map['valid_until'].toString()) : null,
      isActive: map['is_active'] is bool ? map['is_active'] as bool : (map['is_active'] != null ? (map['is_active'].toString().toLowerCase() == 'true') : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'restaurant_id': restaurantId,
      'discount_percentage': discountPercentage,
      'valid_until': validUntil?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
