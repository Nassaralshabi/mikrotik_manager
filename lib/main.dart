import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/app_providers.dart';
import 'services/cache_service.dart';
import 'services/log_service.dart';
import 'services/search_service.dart';
import 'services/theme_service.dart';
import 'l10n/locale_provider.dart';
import 'l10n/app_localizations_delegate.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local caching
  await Hive.initFlutter();

  // Initialize cache service
  await CacheService().init();

  // Initialize log service for activity logging
  await LogService.init();

  // Initialize search service for recent searches
  await SearchService.init();

  // Initialize mobile ads
  await AdService().init();

  // Pre-load theme for instant display (no flash)
  final preloadedTheme = await ThemeService.loadThemeMode();

  // Pre-load locale
  final preloadedLocale = await LocaleService.loadLocale();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider
            .overrideWith((ref) => ThemeModeNotifier.preloaded(preloadedTheme)),
        localeProvider
            .overrideWith((ref) => LocaleNotifier.preloaded(preloadedLocale)),
      ],
      child: const OmmonApp(),
    ),
  );
}

class OmmonApp extends ConsumerWidget {
  const OmmonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ΩMMON - Open Mikrotik Monitor',
      theme: ThemeService.getThemeData(themeMode),
      routerConfig: router,
      locale: locale,
      supportedLocales: LocaleService.supportedLocales,
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        return locale;
      },
      builder: (context, child) {
        // Force RTL layout for Arabic
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
