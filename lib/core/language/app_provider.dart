import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

class AppLanguageState {
  final String locale;
  final Map<String, String> translations;

  AppLanguageState({
    required this.locale,
    required this.translations,
  });

  AppLanguageState copyWith({
    String? locale,
    Map<String, String>? translations,
  }) {
    return AppLanguageState(
      locale: locale ?? this.locale,
      translations: translations ?? this.translations,
    );
  }
}

class AppLanguageNotifier extends StateNotifier<AppLanguageState> {
  final Ref ref;

  AppLanguageNotifier(this.ref, AppLanguageState initialState) : super(initialState);

  Future<void> changeLocale(String localeCode) async {
    if (localeCode != 'vi' && localeCode != 'en') {
      localeCode = 'vi'; // Fallback
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/translations/$localeCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final translations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      
      state = AppLanguageState(
        locale: localeCode,
        translations: translations,
      );
      
      // Save to local storage
      final storage = ref.read(localStoreHelperProvider);
      await storage.saveLanguageCode(localeCode);
    } catch (e) {
      // In case of error, fallback or retain existing
    }
  }
}

final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguageState>((ref) {
  throw UnimplementedError('Override appLanguageProvider in main.dart');
});

final localeProvider = Provider<String>((ref) {
  return ref.watch(appLanguageProvider).locale;
});

final translationsProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(appLanguageProvider).translations;
});
