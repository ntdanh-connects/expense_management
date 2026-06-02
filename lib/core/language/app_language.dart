import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_provider.dart';

extension TranslateExtension on String {
  /// Translates a static translation key using Riverpod's ref.
  /// Usage: `'my_key'.tr(ref)`
  String tr(dynamic ref) {
    final translations = ref.watch(translationsProvider);
    return translations[this] ?? this;
  }
}
