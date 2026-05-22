import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeMode> {

  @override
  ThemeMode build() {
    final storage = ref.read(localStoreHelperProvider);
    final themeIndex = storage.getThemeIndex();
    if (themeIndex != null) {
      return ThemeMode.values[themeIndex];
    }
    return ThemeMode.system;
  }

  // Hàm đổi Theme mượt mà + Sync Local + Sync DB ngầm
  Future<void> toggleTheme() async {
    final storage = ref.read(localStoreHelperProvider);
    final currentTheme = state;
    final newTheme = currentTheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    state = newTheme;

    storage.saveThemeIndex(newTheme.index);

    _syncThemeToDatabase(newTheme == ThemeMode.dark ? 'dark' : 'light');
  }

  void _syncThemeToDatabase(String themeStr) {
    try {
      // ref.read(userRepositoryProvider).updatePreferences(theme: themeStr);
    } catch (_) {
      //To be continue
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);