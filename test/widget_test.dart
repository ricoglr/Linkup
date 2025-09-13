// This is a basic Flutter widget test for the Linkup app.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:linkup_app/main.dart';
import 'package:linkup_app/theme/theme_provider.dart';

void main() {
  group('Linkup App Tests', () {
    testWidgets('App starts with login screen', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
          child: const MyApp(),
        ),
      );

      // Verify that the app shows login screen elements
      expect(find.text('LINK UP'), findsOneWidget);
      expect(find.text('Giriş Yap'), findsOneWidget);
    });

    testWidgets('Theme provider toggles theme', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();

      // Test initial state
      expect(themeProvider.isDarkMode, false);

      // Toggle theme
      themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);

      // Toggle back
      themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, false);
    });
  });
}
