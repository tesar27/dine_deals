import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

// Change to StateProvider to allow updating
final mapControllerProvider = StateProvider<MapController?>((ref) {
  return null; // Start with null, will be set after map is rendered
});
