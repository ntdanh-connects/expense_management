import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/storage/local_storage_helper.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        localStoreHelperProvider.overrideWithValue(
          LocalStorageHelper(sharedPrefs)
        )
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
    );
  }
}