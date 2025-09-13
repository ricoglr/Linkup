// Mock Firebase için test dosyası
import 'package:flutter_test/flutter_test.dart';
import 'package:linkup_app/theme/theme_provider.dart';

void main() {
  group('Theme Provider Tests', () {
    test('Initial theme should be light', () {
      final themeProvider = ThemeProvider();
      expect(themeProvider.isDarkMode, false);
    });

    test('Toggle theme changes mode', () {
      final themeProvider = ThemeProvider();

      // Initial state
      expect(themeProvider.isDarkMode, false);

      // Toggle to dark
      themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);

      // Toggle back to light
      themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, false);
    });
  });
}
