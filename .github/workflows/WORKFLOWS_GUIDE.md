# 🚀 دليل GitHub Actions Workflows

هذا المجلد يحتوي على workflows آلية لبناء وإصدار تطبيق Mikrotik Manager على منصات مختلفة.

---

## 📋 قائمة الـ Workflows

### 1. **build-android-apk.yml** ⭐ (الأحدث - المُوصى به)

**الوصف**: Workflow محسّن لبناء Android APK مع دعم Fat APK و Split APKs.

**متى يعمل تلقائياً:**
- ✅ Push إلى فرع `main` أو `develop`
- ✅ Pull Request إلى فرع `main`
- ✅ عند تغيير ملفات: `lib/**`, `android/**`, `pubspec.yaml`

**التشغيل اليدوي:**
```bash
# من صفحة Actions في GitHub:
Actions → Build Android Release APK → Run workflow
```

**الخيارات المتاحة:**
- **Build Type**:
  - `fat-apk`: بناء APK واحد يعمل على جميع المعالجات (Universal)
  - `split-apk`: بناء APK منفصل لكل معالج (حجم أصغر)
  - `both`: بناء الاثنين معاً
- **Upload Artifacts**: رفع ملفات APK للتحميل

**المميزات:**
- 🎯 استخراج معلومات الإصدار تلقائياً من `pubspec.yaml`
- 📊 عرض معلومات مفصلة عن البناء (الحجم، الإصدار، إلخ)
- 📦 دعم Caching لتسريع البناء
- ⚡ بناء موازي للـ Split APKs
- 📤 رفع Artifacts تلقائياً (صلاحية 30 يوم)

**Output:**
- `mikrotik-manager-v{VERSION}-fat-apk`
- `mikrotik-manager-v{VERSION}-{ABI}-apk` (للـ split builds)

---

### 2. **release.yml**

**الوصف**: Workflow شامل لإنشاء إصدارات رسمية لجميع المنصات.

**متى يعمل:**
- عند إنشاء tag بصيغة `v*.*.*` (مثل: `v1.0.0`)
- تشغيل يدوي مع إدخال رقم الإصدار

**المنصات المدعومة:**
- 🤖 Android (APK + AAB)
- 🌐 Web
- 🪟 Windows
- 🐧 Linux

**كيفية إنشاء إصدار جديد:**
```bash
# 1. إنشاء tag
git tag v1.0.0
git push origin v1.0.0

# 2. أو تشغيل يدوي من GitHub Actions
Actions → Create Release → Run workflow → أدخل رقم الإصدار
```

**Output:**
- إنشاء GitHub Release تلقائياً
- رفع جميع الملفات القابلة للتحميل
- إضافة Release Notes تلقائية

---

### 3. **build-release.yml**

**الوصف**: بناء Android APK و AAB للإصدارات.

**متى يعمل:**
- عند push لـ tags بصيغة `v*.*.*`
- تشغيل يدوي

**Output:**
- `app-release-apk`
- `app-release-aab`

---

### 4. **flutter-apk-release.yml**

**الوصف**: بناء APK عند Pull Requests للاختبار.

**متى يعمل:**
- Pull Request يغير ملفات Android أو Flutter
- تشغيل يدوي

**Flutter Version**: `3.22.3`

---

### 5. **build-multi-platform.yml**

**الوصف**: بناء التطبيق لمنصات متعددة.

---

### 6. **code-quality.yml**

**الوصف**: فحص جودة الكود تلقائياً.

---

### 7. **deploy-web.yml**

**الوصف**: نشر نسخة الويب تلقائياً.

---

## 🎯 أفضل الممارسات

### للتطوير اليومي
استخدم **build-android-apk.yml**:
```bash
# 1. Push للتجربة التلقائية
git push origin main

# 2. أو تشغيل يدوي للاختبار السريع
Actions → Build Android Release APK → Run workflow → اختر "fat-apk"
```

### لإصدار نسخة جديدة
استخدم **release.yml**:
```bash
# 1. حدّث رقم الإصدار في pubspec.yaml
version: 1.2.0+5

# 2. Commit التغييرات
git add pubspec.yaml
git commit -m "Bump version to 1.2.0"

# 3. أنشئ tag
git tag v1.2.0
git push origin main
git push origin v1.2.0

# سيتم إنشاء Release تلقائياً مع جميع الملفات!
```

### للاختبار قبل Pull Request
استخدم **flutter-apk-release.yml**:
```bash
# سيعمل تلقائياً عند فتح PR
# أو تشغيل يدوي من Actions tab
```

---

## 📥 تحميل الملفات المُنتجة

### من Actions Tab
1. اذهب إلى: `Repository → Actions`
2. اختر الـ Workflow run المطلوب
3. نزّل من قسم **Artifacts**

### من Releases
1. اذهب إلى: `Repository → Releases`
2. اختر الإصدار المطلوب
3. حمّل الملفات من قسم **Assets**

---

## 🔧 تخصيص الإعدادات

### تغيير Flutter Version
في أي workflow، عدّل:
```yaml
env:
  FLUTTER_VERSION: '3.24.0'  # غيّر هنا
```

### تغيير Java Version
```yaml
env:
  JAVA_VERSION: '17'  # غيّر هنا
```

### تغيير مدة حفظ Artifacts
```yaml
retention-days: 30  # غيّر المدة (بالأيام)
```

---

## 🐛 حل المشاكل الشائعة

### مشكلة: Workflow لا يعمل تلقائياً
**الحل:**
- تأكد من أن التغييرات في الملفات المُراقبة (`lib/**`, `android/**`, إلخ)
- تحقق من الـ branch name (يجب أن يكون `main` أو `develop`)

### مشكلة: Build فشل بسبب Dependencies
**الحل:**
```bash
# حدّث الـ lock file محلياً
flutter pub get
git add pubspec.lock
git commit -m "Update dependencies"
git push
```

### مشكلة: APK غير موجود في Artifacts
**الحل:**
- تأكد من نجاح خطوة البناء (Build APK)
- تحقق من الـ logs في Actions tab
- تأكد من أن `upload_artifacts` مفعّل (في Manual runs)

---

## 📊 مقارنة Fat APK vs Split APKs

| الميزة | Fat APK | Split APKs |
|--------|---------|------------|
| **الحجم** | ~50-80 MB | ~20-30 MB لكل ملف |
| **التوافق** | يعمل على جميع الأجهزة | ملف منفصل لكل معالج |
| **التوزيع** | سهل (ملف واحد) | يحتاج اختيار الملف المناسب |
| **الاستخدام الموصى به** | للتوزيع المباشر | للمتاجر الإلكترونية |

---

## 🎨 معلومات الإصدار

جميع الـ workflows تستخرج معلومات الإصدار تلقائياً من `pubspec.yaml`:

```yaml
# pubspec.yaml
version: 1.2.0+5
         ↑     ↑
         |     └─ Build Number
         └─ Version Name
```

يتم استخدامها في:
- أسماء الملفات
- Release notes
- Artifacts names
- Build metadata

---

## 📞 الدعم

للأسئلة والمشاكل:
1. تحقق من الـ logs في Actions tab
2. راجع [Flutter Documentation](https://docs.flutter.dev)
3. افتح Issue في الـ repository

---

**آخر تحديث**: نوفمبر 2024
**Flutter Version**: 3.24.0
**Maintained by**: MikroTik Manager Team ❤️
