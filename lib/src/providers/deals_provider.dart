import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'deals_provider.g.dart';

@riverpod
class DealsNotifier extends _$DealsNotifier {
  PostgrestList? _cachedData;
  static const String _cacheKey = 'deals_cache';

  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetchDeals();
  }

  // Fetch all deals from Supabase
  Future<List<Map<String, dynamic>>> _fetchDeals() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_cacheKey);

    if (cachedJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        _cachedData = PostgrestList.from(decoded);
        print("DealsNotifier: Returning data from SharedPreferences");
        return _cachedData!;
      } catch (e) {
        print("DealsNotifier: Error parsing cached data: $e");
        // Continue to fetch from API if parsing fails
      }
    }

    try {
      final dealsData = await Supabase.instance.client
          .from('deals')
          .select()
          .order('created_at', ascending: false);

      try {
        await prefs.setString(_cacheKey, jsonEncode(dealsData));
        print("DealsNotifier: Data saved to SharedPreferences");
      } catch (e) {
        print("DealsNotifier: Error saving to SharedPreferences: $e");
      }

      _cachedData = dealsData;
      return (dealsData as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (error) {
      throw Exception('Failed to fetch deals: $error');
    }
  }

  // Add a new deal
  Future<void> addDeal({
    required String restaurantId,
    required String name,
    required String description,
    required double savings,
    String? category,
  }) async {
    try {
      // Save the new deal to Supabase
      await Supabase.instance.client.from('deals').insert({
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'savings': savings,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Clear cached data to ensure fresh data is loaded next time
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);

      // Refresh the deals list
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to add deal: $error');
    }
  }

  // Get deals for a specific restaurant
  Future<List<Map<String, dynamic>>> getDealsForRestaurant(
      String restaurantId) async {
    try {
      // First try to use cached data if available
      if (_cachedData != null) {
        return _cachedData!
            .where((deal) => deal['restaurant_id'].toString() == restaurantId)
            .toList();
      }

      // Otherwise fetch from Supabase
      final dealsData = await Supabase.instance.client
          .from('deals')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);

      return (dealsData as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (error) {
      throw Exception('Failed to fetch deals for restaurant: $error');
    }
  }

  // Delete a deal (admin functionality)
  Future<void> deleteDeal(String dealId) async {
    try {
      await Supabase.instance.client.from('deals').delete().eq('id', dealId);

      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);

      // Refresh the deals list
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to delete deal: $error');
    }
  }

  // Update an existing deal (admin functionality)
  Future<void> updateDeal({
    required String dealId,
    String? name,
    String? description,
    double? savings,
    String? category,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (savings != null) updates['savings'] = savings;
      if (category != null) updates['category'] = category;

      await Supabase.instance.client
          .from('deals')
          .update(updates)
          .eq('id', dealId);

      // Clear cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);

      // Refresh the deals list
      ref.invalidateSelf();
    } catch (error) {
      throw Exception('Failed to update deal: $error');
    }
  }
}
