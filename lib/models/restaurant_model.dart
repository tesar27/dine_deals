class Restaurant {
  final int id;
  final String name;
  final String address;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final double? rating;
  final String? hours;
  final String? minOrder;
  final List<String>? categories;
  final int? dealsCount;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.rating,
    this.categories,
    this.dealsCount,
    this.hours,
    this.minOrder,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? '') ?? 0,
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString(),
      country: map['country']?.toString(),
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
  imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString(),
      rating: map['rating'] != null ? double.tryParse(map['rating'].toString()) : null,
  hours: map['hours']?.toString(),
  minOrder: map['minOrder']?.toString() ?? map['min_order']?.toString(),
      categories: map['categories'] == null
          ? null
          : (map['categories'] is List
              ? (map['categories'] as List).map((e) => e.toString()).toList()
              : map['categories'].toString().split(',').map((e) => e.trim()).toList()),
      dealsCount: map['deals_count'] is int ? map['deals_count'] as int : (map['deals_count'] != null ? int.tryParse(map['deals_count'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'rating': rating,
      'categories': categories,
      'deals_count': dealsCount,
      'hours': hours,
      'min_order': minOrder,
    };
  }
}
