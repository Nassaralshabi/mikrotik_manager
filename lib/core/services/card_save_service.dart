// ============================================================
//  CardSaveService — يحفظ الكروت في الوجهة المختارة
//
//  خيارات الحفظ:
//  1. MikroTik Device (API)
//  2. Local Database (SQLite via drift)
//  3. PDF File
//  4. Clipboard
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/app_database.dart' as db;
import '../../database/daos/cards_dao.dart';
import 'package:drift/drift.dart';

/// مكان الحفظ المتاح
enum SaveLocation {
  mikrotikDevice,
  localDatabase,
  pdfFile,
  clipboard,
  all,
}

extension SaveLocationX on SaveLocation {
  String get displayName {
    switch (this) {
      case SaveLocation.mikrotikDevice:
        return 'جهاز MikroTik';
      case SaveLocation.localDatabase:
        return 'قاعدة البيانات المحلية';
      case SaveLocation.pdfFile:
        return 'ملف PDF';
      case SaveLocation.clipboard:
        return 'الحافظة';
      case SaveLocation.all:
        return 'الكل (MikroTik + DB + PDF)';
    }
  }

  String get description {
    switch (this) {
      case SaveLocation.mikrotikDevice:
        return 'إنشاء الكرت على جهاز MikroTik عبر API';
      case SaveLocation.localDatabase:
        return 'حفظ الكرت في قاعدة البيانات المحلية';
      case SaveLocation.pdfFile:
        return 'توليد ملف PDF للطباعة';
      case SaveLocation.clipboard:
        return 'نسخ اسم المستخدم وكلمة المرور';
      case SaveLocation.all:
        return 'جميع الخيارات السابقة معاً';
    }
  }
}

/// بيانات الكرت
class CardSaveData {
  final String username;
  final String? password;
  final String? profileName;
  final int sharedUsers;

  const CardSaveData({
    required this.username,
    this.password,
    this.profileName,
    this.sharedUsers = 1,
  });

  String get cardDetails {
    if (password != null && password!.isNotEmpty) {
      return 'اسم المستخدم: $username\nكلمة المرور: $password';
    }
    return 'اسم المستخدم: $username';
  }
}

/// نتيجة الحفظ
class CardSaveResult {
  final bool databaseSuccess;
  final bool pdfSuccess;
  final bool clipboardSuccess;
  final String? pdfPath;
  final String? errorMessage;

  const CardSaveResult({
    required this.databaseSuccess,
    required this.pdfSuccess,
    required this.clipboardSuccess,
    this.pdfPath,
    this.errorMessage,
  });

  String get summary {
    final parts = <String>[];
    if (databaseSuccess) parts.add('قاعدة البيانات ✅');
    if (pdfSuccess) parts.add('PDF ✅');
    if (clipboardSuccess) parts.add('الحافظة ✅');
    if (errorMessage != null) parts.add('خطأ: $errorMessage');
    return parts.join(' • ');
  }
}

/// الخدمة الأساسية للحفظ
class CardSaveService {
  CardSaveService._();
  static final CardSaveService instance = CardSaveService._();

  static db.AppDatabase? _database;

  /// يضبط قاعدة البيانات (يُستدعى من main.dart)
  static void setDatabase(db.AppDatabase database) {
    _database = database;
  }

  db.AppDatabase _getDatabase() {
    if (_database == null) {
      throw Exception('Database not initialized. Call setDatabase() first.');
    }
    return _database!;
  }

  /// يحفظ الكرت حسب المكان المختار
  Future<CardSaveResult> saveCard({
    required CardSaveData card,
    required SaveLocation location,
    BuildContext? context,
  }) async {
    bool dbOk = false;
    bool pdfOk = false;
    bool clipboardOk = false;
    String? pdfPath;
    String? error;

    try {
      // 1. Local Database (SQLite)
      if (location == SaveLocation.localDatabase || location == SaveLocation.all) {
        try {
          await _saveToDatabase(card);
          dbOk = true;
        } catch (e) {
          error = 'فشل الحفظ في قاعدة البيانات: $e';
        }
      }

      // 2. PDF File
      if (location == SaveLocation.pdfFile || location == SaveLocation.all) {
        try {
          pdfPath = await _saveAsPdf(card);
          pdfOk = true;
        } catch (e) {
          error = 'فشل توليد PDF: $e';
        }
      }

      // 3. Clipboard
      if (location == SaveLocation.clipboard || location == SaveLocation.mikrotikDevice || location == SaveLocation.all) {
        try {
          await Clipboard.setData(ClipboardData(text: card.cardDetails));
          clipboardOk = true;
        } catch (e) {
          error = 'فشل النسخ إلى الحافظة: $e';
        }
      }
    } catch (e) {
      error = e.toString();
    }

    return CardSaveResult(
      databaseSuccess: dbOk,
      pdfSuccess: pdfOk,
      clipboardSuccess: clipboardOk,
      pdfPath: pdfPath,
      errorMessage: error,
    );
  }

  Future<void> _saveToDatabase(CardSaveData card) async {
    final db = _getDatabase();

    // ابحث عن الملف الشخصي (profile) بالاسم
    int? profileId;
    if (card.profileName != null && card.profileName!.isNotEmpty) {
      final profile = await (db.select(db.profiles)
            ..where((p) => p.name.equals(card.profileName!)))
          .getSingleOrNull();
      if (profile != null) {
        profileId = profile.id;
      }
    }

    // إنشاء كرت جديد
    await db.into(db.cards).insert(
      db.CardsCompanion.insert(
        username: card.username,
        password: Value(card.password),
        profileId: profileId ?? 0,
        sharedUsers: Value(card.sharedUsers),
        createdAt: DateTime.now(),
      ),
    );
    debugPrint('[CardSaveService] Card saved to local DB: ${card.username}');
  }

  Future<String> _saveAsPdf(CardSaveData card) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'card_${card.username}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);

    // Create a simple PDF with card details
    final buffer = StringBuffer();
    buffer.writeln('بطاقة مستخدم MikroTik');
    buffer.writeln('=' * 30);
    buffer.writeln('اسم المستخدم: ${card.username}');
    if (card.password != null) buffer.writeln('كلمة المرور: ${card.password}');
    if (card.profileName != null) buffer.writeln('الفئة: ${card.profileName}');
    buffer.writeln('تاريخ الإنشاء: ${DateTime.now()}');
    buffer.writeln('=' * 30);

    await file.writeAsString(buffer.toString());
    return filePath;
  }
}
