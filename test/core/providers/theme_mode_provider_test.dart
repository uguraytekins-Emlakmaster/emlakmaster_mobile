import 'package:emlakmaster_mobile/core/providers/settings_provider.dart';
import 'package:emlakmaster_mobile/core/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('theme mode persistence helpers', () {
    test('store indices round-trip with ThemeMode values', () {
      expect(themeModeIndexToStore(ThemeMode.system), 0);
      expect(themeModeIndexToStore(ThemeMode.light), 1);
      expect(themeModeIndexToStore(ThemeMode.dark), 2);

      expect(themeModeFromIndex(0), ThemeMode.system);
      expect(themeModeFromIndex(1), ThemeMode.light);
      expect(themeModeFromIndex(2), ThemeMode.dark);
      expect(themeModeFromIndex(999), ThemeMode.dark);
    });

    test('provider maps restored index to ThemeMode', () {
      ThemeMode readFor(int index) {
        final container = ProviderContainer(
          overrides: [
            initialThemeModeIndexProvider.overrideWithValue(index),
          ],
        );
        addTearDown(container.dispose);
        return container.read(themeModeProvider);
      }

      expect(readFor(0), ThemeMode.system);
      expect(readFor(1), ThemeMode.light);
      expect(readFor(2), ThemeMode.dark);
    });
  });
}
