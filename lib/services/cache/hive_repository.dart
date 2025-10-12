import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dine_deals/models/restaurant_model.dart';

class HiveRepository {
  static const String restaurantsBox = 'restaurants_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    // Open an untyped box for now. We store Map<String, dynamic> entries so
    // that Hive can be used as a fast key/value cache without requiring a
    // generated TypeAdapter during development. Once adapters are generated
    // we can migrate to typed boxes and register adapters before opening.
    await Hive.openBox(restaurantsBox);
  }

  static Box _box() => Hive.box(restaurantsBox);

  /// Persist restaurants as plain maps keyed by their id. This avoids
  /// requiring a generated TypeAdapter while still providing a fast local
  /// cache for typed reads.
  static Future<void> saveRestaurants(List<Restaurant> restaurants) async {
    final box = _box();
    await box.clear();
    for (final r in restaurants) {
      await box.put(r.id.toString(), r.toMap());
    }
  }

  /// Returns a list of [Restaurant] instances constructed from stored maps
  /// or from already-typed objects if the box contains them.
  static List<Restaurant> getAllRestaurants() {
    final box = _box();
    final values = box.values.toList();
    final results = <Restaurant>[];
    for (final v in values) {
      if (v is Restaurant) {
        results.add(v);
      } else if (v is Map) {
        // Stored as a plain map (the common path)
        results.add(Restaurant.fromMap(Map<String, dynamic>.from(v)));
      } else if (v is String) {
        try {
          final decoded = Map<String, dynamic>.from(jsonDecode(v));
          results.add(Restaurant.fromMap(decoded));
        } catch (_) {
          // Ignore unknown item types
        }
      }
    }
    return results;
  }

  static Future<void> clear() async {
    final box = _box();
    await box.clear();
  }
}
