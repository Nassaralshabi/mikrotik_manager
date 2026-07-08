import 'package:flutter/material.dart';
import 'translations.dart';
import 'locale_provider.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return LocaleService.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppStrings> load(Locale locale) async {
    return AppStrings(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => true;
}
