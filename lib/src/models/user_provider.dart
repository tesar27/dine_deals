import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_provider.g.dart';

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<Map<String, dynamic>?> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      print(
          "UserNotifier: Fetching user data for ID: $userId"); // Optional: for debugging

      // .single() returns the Map directly on success or throws on error
      final userData = await Supabase.instance.client
          .from('users')
          .select() // Selects all columns by default
          .eq('id', userId)
          .single(); // Returns PostgrestMap (Map<String, dynamic>) or throws PostgrestException

      print(
          "UserNotifier: User data fetched successfully."); // Optional: for debugging
      // If we reach here, the query was successful and userData is the Map
      return userData; // Type is already Map<String, dynamic>
    } on PostgrestException catch (error) {
      // Handle specific Supabase errors
      print(
          "UserNotifier: Failed to fetch user data. Supabase error: ${error.message}");
      // Re-throw the error or a custom exception so Riverpod can handle the error state
      // This allows AsyncValue.error() state in the UI
      throw Exception(
          'Failed to load user profile: ${error.message}'); // Or rethrow error;
    } catch (error) {
      // Catch any other unexpected errors
      print("UserNotifier: An unexpected error occurred: $error");
      throw Exception('An unexpected error occurred while fetching user data.');
    }
  }
}

extension on PostgrestMap {}
