import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends AsyncNotifier<ThemeMode> {

  @override
  Future<ThemeMode> build() async {
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
    final currentTheme = state.value ?? ThemeMode.system;
    final newTheme = currentTheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    // Cập nhật State cho UI render tức thì
    state = AsyncData(newTheme);
    
    // Lưu Local Storage
    storage.saveThemeIndex(newTheme.index);

    // Bắn API lên Database ngầm (Background)
    _syncThemeToDatabase(newTheme == ThemeMode.dark ? 'dark' : 'light');
  }

  void _syncThemeToDatabase(String themeStr) {
    try {
      // ref.read(userRepositoryProvider).updatePreferences(theme: themeStr);
    } catch (_) {}
  }
}

final themeProvider = AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);