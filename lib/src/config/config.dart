import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static final opencageApi = dotenv.env['OPENCAGE_API'] ?? '';
  static final opencageUrl = dotenv.env['OPENCAGE_URL'] ?? '';
}
