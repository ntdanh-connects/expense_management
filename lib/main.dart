import 'dart:ui';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:expense_management/core/config/app_config.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/storage/local_storage_helper.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/core/utils/log_console_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:expense_management/core/network/dio_client.dart';
import 'package:expense_management/features/notification/data/datasource/local/local_notification_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await LocalNotificationService.initialize();
  await initializeDateFormatting('vi', null);
  await initializeDateFormatting('en', null);
  final sharedPrefs = await SharedPreferences.getInstance();
  final tempDir = await getTemporaryDirectory();
  final cacheStore = FileCacheStore(p.join(tempDir.path, 'http_cache'));

  if (AppConfig.enableLogging) {
    // Bắt lỗi Flutter toàn cục và lưu lại (Chỉ kích hoạt trong DEV)
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        details.exceptionAsString(),
        tag: 'FlutterError',
        stackTrace: details.stack,
        details: details.context?.toString(),
      );
    };

    // Bắt lỗi hệ thống/nền toàn cục của Dart (Chỉ kích hoạt trong DEV)
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error(
        error.toString(),
        tag: 'UncaughtError',
        stackTrace: stack,
      );
      return true;
    };
  }

  // Khởi tạo trạng thái ẩn/hiện nút nổi (Bắt buộc ẩn khi ở môi trường LIVE)
  final showOverlay = AppConfig.enableLogging && (sharedPrefs.getBool('show_developer_console') ?? true);
  AppLogger.isConsoleOverlayVisible.value = showOverlay;

  // Preload translation map
  final localStorage = LocalStorageHelper(sharedPrefs);
  final savedLocale = localStorage.getLanguageCode() ?? 'vi';
  Map<String, String> initialTranslations = {};
  try {
    final jsonString = await rootBundle.loadString('assets/translations/$savedLocale.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    initialTranslations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  } catch (e) {
    try {
      final jsonString = await rootBundle.loadString('assets/translations/vi.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      initialTranslations = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {}
  }

  runApp(
    ProviderScope(
      overrides: [
        localStoreHelperProvider.overrideWithValue(
          LocalStorageHelper(sharedPrefs)
        ),
        cacheStoreProvider.overrideWithValue(cacheStore),
        appLanguageProvider.overrideWith((ref) => AppLanguageNotifier(
          ref,
          AppLanguageState(
            locale: savedLocale,
            translations: initialTranslations,
          ),
        )),
      ],
      child: MyApp()
    )
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'EM',
      debugShowCheckedModeBanner: false,

      routerConfig: router,

      themeMode: themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColorsExtension.light.background,
        primaryColor: AppColorsExtension.light.primary,
        extensions: [AppColorsExtension.light],
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColorsExtension.dark.background,
        primaryColor: AppColorsExtension.dark.primary,
        extensions: [AppColorsExtension.dark],
      ),

      builder: (context, child) {
        return LogConsoleOverlay(child: child!);
      },
    );
  }
}