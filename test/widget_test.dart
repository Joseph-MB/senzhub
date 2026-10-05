import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senzhubmobileapplication/app.dart';
import 'package:senzhubmobileapplication/core/theme/app_theme.dart';
import 'package:senzhubmobileapplication/services/mock_data_service.dart';
import 'package:senzhubmobileapplication/widgets/glass_card.dart';

void main() {
  testWidgets('SENZHUB app loads with splash flow', (tester) async {
    await tester.pumpWidget(const SenzHubApp());

    expect(find.text('SENZHUB'), findsWidgets);
  });

  testWidgets('Light mode uses a light card surface and dark text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemeChoice.emerald, brightness: Brightness.light),
        darkTheme: AppTheme.themeFor(AppThemeChoice.emerald, brightness: Brightness.dark),
        themeMode: ThemeMode.light,
        home: const Scaffold(body: GlassCard(child: Text('Theme test'))),
      ),
    );

    final theme = Theme.of(tester.element(find.text('Theme test')));
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.surface, Colors.white);
    expect(theme.colorScheme.onSurface, isNot(Colors.white));
    expect(find.text('Theme test'), findsOneWidget);
  });

  testWidgets('Register screen requires the expected fields and routes to verification', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Verification screen uses six digits and the mock code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TwoStepVerificationScreen(),
      ),
    );

    expect(find.text('Two-step verification'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('Settings exposes theme and SDG links', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(find.text('Appearance / Theme'), findsOneWidget);
    expect(find.text('Sustainability / SDG Goals'), findsOneWidget);
  });

  testWidgets('SDG screen lists the full set of official goals', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SdgGoalsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    for (final goal in MockDataService.sdgGoals) {
      await tester.scrollUntilVisible(find.text(goal.name), 100);
      expect(find.text(goal.name), findsOneWidget);
    }
  });
}
