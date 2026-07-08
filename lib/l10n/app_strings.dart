import 'package:flutter/material.dart';
import 'translations.dart';

extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
