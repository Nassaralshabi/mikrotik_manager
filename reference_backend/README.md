# NUM Backend System - نظام NUM للخلفية

هذا هو النظام الخلفي (Backend) لتطبيق NUM لإدارة بطاقات الإنترنت مع أجهزة MikroTik.

## نظرة عامة

نظام NUM هو نظام متكامل لإدارة بطاقات الإنترنت يتضمن:

- إدارة العملاء والمستخدمين
- طباعة البطاقات مع رموز QR
- تقارير المبيعات والعمولات
- التكامل مع أجهزة MikroTik Router

## ملفات النظام

### ملفات PHP الرئيسية

- `api.php` - فئة API الرئيسية للتفاعل مع MikroTik RouterOS
- `login.php` - نظام تسجيل الدخول
- `users.php` - إدارة المستخدمين
- `customer.php` - إدارة العملاء
- `devices.php` - إدارة الأجهزة

### إدارة البروفايلات

- `add_profile.php` - إضافة بروفايل جديد
- `edit_profile.php` - تعديل البروفايل
- `remove_profile.php` - حذف البروفايل
- `load_profile.php` - تحميل بيانات البروفايل

### إدارة البطاقات

- `AddCards.php` - إضافة بطاقات جديدة
- `load_card_finished.php` - تحميل البطاقات المكتملة
- `Block.php` - حظر البطاقات

### التقارير والبيانات

- `getAllDataUserManager.php` - جلب جميع بيانات المستخدمين
- `load_info.php` - تحميل المعلومات العامة
- `load_payment.php` - تحميل بيانات الدفع
- `load_active.php` - تحميل المستخدمين النشطين
- `info_router.php` - معلومات الراوتر

### ملفات المساعدة

- `backup.php` - نظام النسخ الاحتياطي
- `eviction.php` - نظام الطرد
- `load_session.php` - إدارة الجلسات
- `sup.php` - ملف المشرف
- `gatallusers.js` - سكربت JavaScript للمستخدمين

## مجلد البطاقات (Cards)

يحتوي على:
- `cards.html` - قالب طباعة البطاقات
- `test.html` - ملف الاختبار
- `js/qrcode.min.js` - مكتبة إنشاء رموز QR
- `font/tajawal.ttf` - خط تجوال العربي
- `img/` - صور البطاقات

## مجلد التقارير (Reports)

يحتوي على:
- `index.html` - التقرير الرئيسي
- `reports.html` - صفحة التقارير
- `reportDownload.html` - تقرير التحميلات
- `reportPayment.html` - تقرير المدفوعات
- `styles.css` - أنماط CSS للتقارير
- `font/tajawal.ttf` - خط تجوال العربي
- `codingboss.png` - شعار النظام

## متطلبات النظام

- PHP 7.0 أو أحدث
- خادم ويب (Apache/Nginx)
- جهاز MikroTik Router مع تفعيل API
- قاعدة بيانات (MySQL/SQLite حسب التكوين)

## الاستخدام

1. ارفع الملفات إلى خادم الويب
2. تأكد من صحة إعدادات MikroTik API
3. قم بتكوين قاعدة البيانات
4. ابدأ بتسجيل الدخول باستخدام `login.php`

## المطور

تم تطويره بواسطة المهندس نجيب مراد
للاستفسار والاستعلام: +967772339262

---

## Backend System Structure

This backend system provides comprehensive management for internet card distribution with MikroTik integration, including user management, card printing with QR codes, sales reporting, and commission tracking.

### Key Features

- **MikroTik Integration**: Full RouterOS API integration
- **Card Management**: Print and track internet cards with QR codes
- **User Management**: Comprehensive user and customer management
- **Reporting**: Detailed sales and commission reports
- **Arabic Support**: Full RTL support with Tajawal font