// ============================================================
//  Mock لـ FlutterSecureStorage — للاستخدام في الاختبارات
//  تخزين في الذاكرة (In-memory) بدل التخزين الآمن الحقيقي
// ============================================================

/// محاكاة في الذاكرة لـ FlutterSecureStorage
/// يُستخدم في الاختبارات بدلاً من المثيل الحقيقي
class MockFlutterSecureStorage {
  final Map<String, String> _store = {};

  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  Future<String?> read({required String key}) async {
    return _store[key];
  }

  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  Future<void> deleteAll() async {
    _store.clear();
  }

  Map<String, String> get allValues => Map.unmodifiable(_store);

  void setMockValues(Map<String, String> values) {
    _store.clear();
    _store.addAll(values);
  }
}
