import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeChoice {
  emerald('Emerald'),
  teal('Teal'),
  blue('Blue'),
  violet('Violet'),
  amber('Amber');

  const AppThemeChoice(this.label);

  final String label;
}

enum AppAppearanceMode {
  dark('Dark'),
  light('Light'),
  system('System default');

  const AppAppearanceMode(this.label);

  final String label;
}

class AppThemePalette {
  const AppThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.accent,
    required this.accentSoft,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color accent;
  final Color accentSoft;
}

class AppTheme {
  AppTheme._();

  static Color background = const Color(0xFF071411);
  static Color surface = const Color(0xFF0E1E1A);
  static Color surfaceElevated = const Color(0xFF122821);
  static Color accent = const Color(0xFF23D18B);
  static Color accentSoft = const Color(0xFF80F2BE);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF5F6D);
  static const Color info = Color(0xFF5DD7FF);
  static const Color muted = Color(0xFF8BA7A1);

  static const List<AppThemeChoice> themeChoices = [
    AppThemeChoice.emerald,
    AppThemeChoice.teal,
    AppThemeChoice.blue,
    AppThemeChoice.violet,
    AppThemeChoice.amber,
  ];

  static const List<AppAppearanceMode> appearanceChoices = [
    AppAppearanceMode.dark,
    AppAppearanceMode.light,
    AppAppearanceMode.system,
  ];

  static AppThemeChoice _selectedTheme = AppThemeChoice.emerald;
  static AppAppearanceMode _selectedAppearanceMode = AppAppearanceMode.dark;

  static AppThemeChoice get selectedTheme => _selectedTheme;
  static AppAppearanceMode get selectedAppearanceMode =>
      _selectedAppearanceMode;
  static ThemeMode get themeMode {
    switch (_selectedAppearanceMode) {
      case AppAppearanceMode.dark:
        return ThemeMode.dark;
      case AppAppearanceMode.light:
        return ThemeMode.light;
      case AppAppearanceMode.system:
        return ThemeMode.system;
    }
  }

  static ThemeData themeFor(
    AppThemeChoice choice, {
    Brightness brightness = Brightness.dark,
  }) {
    final palette = paletteFor(choice);
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? palette.surface : const Color(0xFFFFFFFF);
    final background = isDark ? palette.background : const Color(0xFFF5F8F7);
    final elevated = isDark ? palette.surfaceElevated : const Color(0xFFEAF1F0);
    final softContainer = isDark
        ? palette.surfaceElevated
        : const Color(0xFFF0F5F4);
    final textPrimary = isDark ? Colors.white : const Color(0xFF15211F);
    final textSecondary = isDark
        ? const Color(0xFF8BA7A1)
        : const Color(0xFF4D6260);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final cardSurface = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFFFFFFF);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: palette.accent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: brightness,
        surface: surface,
        surfaceContainerLowest: softContainer,
        surfaceContainerHighest: elevated,
        primary: palette.accent,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? Colors.black.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.78),
        indicatorColor: palette.accent.withValues(alpha: isDark ? 0.18 : 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: textPrimary, fontWeight: FontWeight.w600);
          }
          return TextStyle(color: textSecondary, fontWeight: FontWeight.w500);
        }),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        surface: surface,
        surfaceContainerHighest: elevated,
        primary: palette.accent,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
      ),
    );
  }

  static ThemeData get lightTheme =>
      themeFor(_selectedTheme, brightness: Brightness.light);
  static ThemeData get darkTheme =>
      themeFor(_selectedTheme, brightness: Brightness.dark);

  static AppThemePalette paletteFor(AppThemeChoice choice) {
    switch (choice) {
      case AppThemeChoice.emerald:
        return const AppThemePalette(
          background: Color(0xFF071411),
          surface: Color(0xFF0E1E1A),
          surfaceElevated: Color(0xFF122821),
          accent: Color(0xFF23D18B),
          accentSoft: Color(0xFF80F2BE),
        );
      case AppThemeChoice.teal:
        return const AppThemePalette(
          background: Color(0xFF081A1D),
          surface: Color(0xFF0E2328),
          surfaceElevated: Color(0xFF12313A),
          accent: Color(0xFF42C7D4),
          accentSoft: Color(0xFF9DEBF4),
        );
      case AppThemeChoice.blue:
        return const AppThemePalette(
          background: Color(0xFF08131C),
          surface: Color(0xFF0E2232),
          surfaceElevated: Color(0xFF12314A),
          accent: Color(0xFF5DA8FF),
          accentSoft: Color(0xFFAAD5FF),
        );
      case AppThemeChoice.violet:
        return const AppThemePalette(
          background: Color(0xFF120D1E),
          surface: Color(0xFF1E1830),
          surfaceElevated: Color(0xFF2D2140),
          accent: Color(0xFF9A7BFF),
          accentSoft: Color(0xFFC9BEFF),
        );
      case AppThemeChoice.amber:
        return const AppThemePalette(
          background: Color(0xFF1B1207),
          surface: Color(0xFF2B1B0D),
          surfaceElevated: Color(0xFF3A260F),
          accent: Color(0xFFF2B74A),
          accentSoft: Color(0xFFF8D389),
        );
    }
  }

  static final ValueNotifier<AppThemeChoice> themeNotifier = ValueNotifier(
    _selectedTheme,
  );
  static final ValueNotifier<AppAppearanceMode> appearanceNotifier =
      ValueNotifier(_selectedAppearanceMode);

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeValue = prefs.getString('senzhub_theme');
    final theme = AppThemeChoice.values.firstWhere(
      (choice) => choice.name == themeValue,
      orElse: () => AppThemeChoice.emerald,
    );
    _selectedTheme = theme;

    final appearanceValue = prefs.getString('senzhub_appearance_mode');
    final appearance = AppAppearanceMode.values.firstWhere(
      (mode) => mode.name == appearanceValue,
      orElse: () => AppAppearanceMode.dark,
    );
    _selectedAppearanceMode = appearance;

    final palette = paletteFor(theme);
    background = palette.background;
    surface = palette.surface;
    surfaceElevated = palette.surfaceElevated;
    accent = palette.accent;
    accentSoft = palette.accentSoft;

    themeNotifier.value = theme;
    appearanceNotifier.value = appearance;
  }

  static Future<void> loadThemePreference() => loadSettings();

  static Future<void> persistTheme(AppThemeChoice choice) async {
    _selectedTheme = choice;
    final palette = paletteFor(choice);
    background = palette.background;
    surface = palette.surface;
    surfaceElevated = palette.surfaceElevated;
    accent = palette.accent;
    accentSoft = palette.accentSoft;
    themeNotifier.value = choice;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('senzhub_theme', choice.name);
  }

  static Future<void> persistAppearanceMode(AppAppearanceMode mode) async {
    _selectedAppearanceMode = mode;
    appearanceNotifier.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('senzhub_appearance_mode', mode.name);
  }
}
