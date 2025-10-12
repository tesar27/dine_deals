import 'package:hive/hive.dart';
import 'package:dine_deals/models/restaurant_model.dart';

/// Manual Hive [TypeAdapter] implementation for [Restaurant].
///
/// This follows the same structure as the generated adapters so that the
/// app can persist Restaurant instances to a Hive box without requiring
/// code generation for now.
class RestaurantAdapter extends TypeAdapter<Restaurant> {
  @override
  final int typeId = 1;

  @override
  Restaurant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Restaurant(
      id: fields[0] as int,
      name: fields[1] as String,
      address: fields[2] as String,
      city: fields[3] as String?,
      country: fields[4] as String?,
      latitude: fields[5] as double?,
      longitude: fields[6] as double?,
      imageUrl: fields[7] as String?,
      rating: fields[8] as double?,
      hours: fields[9] as String?,
      minOrder: fields[10] as String?,
      categories: (fields[11] as List?)?.cast<String>(),
      dealsCount: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Restaurant obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.imageUrl)
      ..writeByte(8)
      ..write(obj.rating)
      ..writeByte(9)
      ..write(obj.hours)
      ..writeByte(10)
      ..write(obj.minOrder)
      ..writeByte(11)
      ..write(obj.categories)
      ..writeByte(12)
      ..write(obj.dealsCount);
  }
}
