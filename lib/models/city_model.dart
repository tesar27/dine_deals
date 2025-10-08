class City {
  final int? id;
  final String name;
  final double? latitude;
  final double? longitude;

  City({this.id, required this.name, this.latitude, this.longitude});

  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] is int ? map['id'] as int : (map['id'] != null ? int.tryParse(map['id'].toString()) : null),
      name: map['name']?.toString() ?? '',
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
