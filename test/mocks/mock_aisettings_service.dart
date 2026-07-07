// ============================================================
//  Mock لـ AiSettingsService — للاستخدام في اختبارات Riverpod
//
//  يجب استخدام mocktail package (موجود في dev_dependencies)
//  بعد تشغيل: flutter pub get
// ============================================================
//
// مثال الاستخدام بعد تثبيت mocktail:
//
// class MockAiSettingsService extends Mock implements AiSettingsService {}
//
// void main() {
//   final mockService = MockAiSettingsService();
//   
//   setUp(() {
//     when(() => mockService.load()).thenAnswer((_) async => AiSettings.default_);
//     when(() => mockService.save(any())).thenAnswer((_) async => {});
//   });
// }
