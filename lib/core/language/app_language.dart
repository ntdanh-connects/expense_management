import 'app_provider.dart';

extension TranslateExtension on String {
  /// Translates a static translation key using Riverpod's ref.
  /// Usage: `'my_key'.tr(ref)`
  String tr(dynamic ref) {
    final translations = ref.watch(translationsProvider);
    return translations[this] ?? this;
  }

  /// Translates a static translation key by reading (no watching).
  /// Safe to use inside button click handlers, initState, callbacks, etc.
  String trRead(dynamic ref) {
    final translations = ref.read(translationsProvider);
    return translations[this] ?? this;
  }
}
