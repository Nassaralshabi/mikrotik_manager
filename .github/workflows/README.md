# GitHub Actions Workflows

هذا المشروع يحتوي على مجموعة شاملة من GitHub Actions workflows لأتمتة عمليات البناء والاختبار والنشر.

## 📋 قائمة الـ Workflows

### 1. 🤖 Build Android APK & AAB on PR
**الملف:** `build-apk.yml`

**التشغيل:** عند فتح أو تحديث Pull Request

**الوظائف:**
- بناء APK للأندرويد
- بناء AAB (Android App Bundle)
- رفع الملفات كـ artifacts
- تشغيل مع Flutter 3.22.3 و Java 17

### 2. 🌐 Multi-Platform Build
**الملف:** `build-multi-platform.yml`

**التشغيل:** عند push لفروع main, develop, feature/** أو Pull Requests

**المنصات المدعومة:**
- 🤖 Android (APK & AAB)
- 🌐 Web (CanvasKit renderer)
- 🐧 Linux (GTK3)
- 🪟 Windows
- 🍎 macOS

**المميزات:**
- بناء متوازي لجميع المنصات
- توليد أيقونات التطبيق تلقائياً
- تقرير شامل للنتائج

### 3. 🚀 Deploy Web App
**الملف:** `deploy-web.yml`

**التشغيل:** عند push للفرع main أو يدوياً

**الوظائف:**
- بناء تطبيق الويب
- نشر على GitHub Pages
- تحسين للأداء مع CanvasKit
- دعم للـ PWA

### 4. 📦 Create Release
**الملف:** `release.yml`

**التشغيل:** عند push tag بصيغة `v*.*.*` أو يدوياً

**المخرجات:**
- 📱 APK & AAB للأندرويد
- 🌐 حزمة Web مضغوطة
- 🪟 حزمة Windows
- 🐧 حزمة Linux
- 📝 Release notes تفصيلية

### 5. 🔍 Code Quality & Testing
**الملف:** `code-quality.yml`

**التشغيل:** مع كل push أو Pull Request

**عمليات الفحص:**
- 📋 تحليل الكود (dart analyze)
- 🎨 فحص التنسيق (dart format)
- 🧪 تشغيل الاختبارات
- 🔒 فحص الأمان (pub audit)
- 🏗️ التحقق من البناء
- 📊 تقرير تغطية الكود

## 🔧 الإعداد والمتطلبات

### متطلبات المستودع
1. **GitHub Pages**: فعّل GitHub Pages للنشر التلقائي للويب
2. **Secrets**: تأكد من وجود `GITHUB_TOKEN` (يتم إنشاؤه تلقائياً)

### متطلبات البناء
- **Flutter**: 3.22.3 (stable)
- **Java**: 17 (للأندرويد)
- **Node.js**: للأدوات المساعدة

## 🚀 كيفية الاستخدام

### للتطوير اليومي
1. قم بعمل push للكود
2. ستعمل workflows التحقق من الجودة تلقائياً
3. للـ Pull Requests، سيتم بناء APK تلقائياً

### للنشر
1. **Web**: push للفرع main سينشر التطبيق على GitHub Pages
2. **Release**: أضف tag بصيغة `v1.0.0` لإنشاء release جديد

### لتشغيل يدوي
استخدم تبويب "Actions" في GitHub وحدد الـ workflow المطلوب

## 📊 الـ Artifacts

### Build Artifacts
- يتم حفظ الملفات لمدة 14-90 يوم
- متاحة للتحميل من صفحة الـ workflow run
- أسماء مميزة تتضمن SHA أو رقم الـ tag

### Release Assets
- متاحة دائماً في صفحة Releases
- تحتوي على جميع المنصات
- ملفات مضغوطة جاهزة للتوزيع

## 🔍 استكشاف الأخطاء

### مشاكل شائعة
1. **فشل بناء Android**: تحقق من إعدادات Java 17
2. **فشل بناء iOS**: يحتاج macOS runner + signing certificates
3. **فشل النشر للويب**: تحقق من إعدادات GitHub Pages

### السجلات
- كل workflow يحتوي على سجلات مفصلة
- استخدم GitHub Actions logs لتتبع المشاكل
- تقارير الملخص متاحة في كل run

## 🎯 النصائح

1. **الأداء**: استخدم caching للـ dependencies
2. **الأمان**: لا تضع secrets في الكود
3. **التحسين**: راجع أوقات التشغيل وحسّن حسب الحاجة
4. **الاختبارات**: أضف المزيد من الاختبارات لتحسين التغطية

---

## 📞 الدعم

لأي مشاكل أو استفسارات حول الـ workflows، يرجى:
1. مراجعة السجلات في GitHub Actions
2. التحقق من متطلبات المشروع
3. فتح issue في المستودع

---

**🏗️ Built with Flutter 3.22.3**  
**✨ Features Qahtani Logo Integration**  
**🚀 Ready for Production Deployment**