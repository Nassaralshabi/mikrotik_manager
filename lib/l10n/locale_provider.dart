import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const _localeKey = 'app_locale';

  static const supportedLocales = [
    Locale('en', ''), // English
    Locale('ar', ''), // العربية
    Locale('id', ''), // Indonesian
    Locale('ms', ''), // Malay
  ];

  static const localeNames = {
    'en': 'English',
    'ar': 'العربية',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
  };

  static const localeFlags = {
    'en': '🇺🇸',
    'ar': '🇸🇦',
    'id': '🇮🇩',
    'ms': '🇲🇾',
  };

  static Future<Locale> loadLocale() async {
    final code = await _storage.read(key: _localeKey);
    if (code != null) {
      return Locale(code);
    }
    // Default to system locale if supported, otherwise English
    final systemLocale = PlatformDispatcher.instance.locale;
    if (supportedLocales
        .any((l) => l.languageCode == systemLocale.languageCode)) {
      return Locale(systemLocale.languageCode);
    }
    // If device locale is Arabic variant (e.g. ar-SA), return Arabic
    if (systemLocale.languageCode == 'ar') {
      return const Locale('ar');
    }
    return const Locale('en');
  }

  static Future<void> saveLocale(Locale locale) async {
    await _storage.write(key: _localeKey, value: locale.languageCode);
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  LocaleNotifier.preloaded(super.locale);

  Future<void> _load() async {
    state = await LocaleService.loadLocale();
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await LocaleService.saveLocale(locale);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
