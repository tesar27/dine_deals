import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static final opencageApi = dotenv.env['OPENCAGE_API'] ?? '';
  static final opencageUrl = dotenv.env['OPENCAGE_URL'] ?? '';
  static final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  static final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
