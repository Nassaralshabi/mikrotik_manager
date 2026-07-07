// ============================================================
//  Test Helpers — أدوات مساعدة للاختبارات
//  تحتوي على:
//  - Mock لـ FlutterSecureStorage
//  - Mock لـ SharedPreferences
//  - إعداد ProviderContainer للاختبارات
//  - Helper لجلب AiSettings للاختبارات
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ينشئ ProviderContainer مُهيّأ للاختبارات
/// مع SharedPreferences و FlutterSecureStorage mock
Future<ProviderContainer> createTestContainer({
  Map<String, String>? secureStorageValues,
  Map<String, Object>? prefsValues,
}) async {
  // تعيين قيم SharedPreferences mocked
  SharedPreferences.setMockInitialValues(prefsValues ?? {});

  // ملاحظة: FlutterSecureStorage يحتاج mock حقيقي من package منفصل
  // لأن setMockInitialValues غير متاح له. سنستخدم mocktail/mockito في المسار الفعلي.
  // للآن، هذه الدالة تهيئ SharedPreferences فقط.

  final container = ProviderContainer();

  return container;
}

/// يوقف ProviderContainer وينظف الموارد
void disposeTestContainer(ProviderContainer container) {
  container.dispose();
}
