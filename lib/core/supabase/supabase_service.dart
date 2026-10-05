import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient? get clientOrNull =>
      isInitialized ? Supabase.instance.client : null;

  // Expose a centralized instance of the Supabase Client
  static SupabaseClient get client => Supabase.instance.client;
}
