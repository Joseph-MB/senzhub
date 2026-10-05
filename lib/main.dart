import 'package:flutter/material.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase backend foundation
  await SupabaseConfig.initialize();

  await AppTheme.loadThemePreference();
  runApp(const SenzHubApp());
}
