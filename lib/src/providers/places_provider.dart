import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'places_provider.g.dart';

@riverpod
class PlacesNotifier extends _$PlacesNotifier {
  @override
  Future<PostgrestList> build() async {
    try {
      // .single() returns the Map directly on success or throws on error
      final placesData = await Supabase.instance.client
          .from('restaurants')
          .select()
          .order('name',
              ascending:
                  true); // Optional: Order by name // Selects all columns by default
      // Returns PostgrestMap (Map<String, dynamic>) or throws PostgrestException

      print(
          "PlacesNotifier: User data fetched successfully."); // Optional: for debugging
      // If we reach here, the query was successful and placesData is the Map
      return placesData; // Type is already Map<String, dynamic>
    } on PostgrestException catch (error) {
      // Handle specific Supabase errors
      print(
          "PlacesNotifier: Failed to fetch user data. Supabase error: ${error.message}");
      // Re-throw the error or a custom exception so Riverpod can handle the error state
      // This allows AsyncValue.error() state in the UI
      throw Exception(
          'Failed to load user profile: ${error.message}'); // Or rethrow error;
    } catch (error) {
      // Catch any other unexpected errors
      print("PlacesNotifier: An unexpected error occurred: $error");
      throw Exception('An unexpected error occurred while fetching user data.');
    }
  }
}

extension on PostgrestMap {}
