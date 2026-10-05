import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");

      final url = dotenv.env['SUPABASE_URL'];
      final publishableKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (url == null ||
          publishableKey == null ||
          url == 'YOUR_SUPABASE_URL' ||
          publishableKey == 'YOUR_SUPABASE_ANON_KEY') {
        throw Exception(
          'Supabase credentials are not configured. '
          'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set correctly in the .env file.',
        );
      }

      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: publishableKey,
      );
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
      rethrow;
    }
  }
}
