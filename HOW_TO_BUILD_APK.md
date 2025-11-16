# 🚀 كيفية بناء APK تلقائياً باستخدام GitHub Actions

## ⚡ الطريقة السريعة

### 1️⃣ بناء تلقائي عند Push
```bash
# أي push لفرع main أو develop سيبني APK تلقائياً
git add .
git commit -m "Your changes"
git push origin main
```

### 2️⃣ بناء يدوي (Manual Run)

1. اذهب إلى repository على GitHub
2. اضغط على تبويب **Actions**
3. اختر **"Build Android Release APK"** من القائمة اليسار
4. اضغط على **"Run workflow"** (الزر الأزرق)
5. اختر الخيارات:
   - **Build Type**: 
     - `fat-apk` → ملف واحد يعمل على جميع الأجهزة (موصى به)
     - `split-apk` → ملفات منفصلة لكل معالج (حجم أصغر)
     - `both` → الاثنين معاً
   - **Upload artifacts**: ✅ فعّل لرفع الملفات
6. اضغط **"Run workflow"**

### 3️⃣ تحميل APK

بعد اكتمال البناء (5-10 دقائق):
1. افتح الـ workflow run الذي اكتمل
2. انزل للأسفل لقسم **"Artifacts"**
3. حمّل ملف APK المطلوب:
   - `mikrotik-manager-v1.0.0-fat-apk` ← ملف واحد للجميع
   - `mikrotik-manager-v1.0.0-arm64-v8a-apk` ← لأجهزة 64-bit الحديثة
   - `mikrotik-manager-v1.0.0-armeabi-v7a-apk` ← لأجهزة 32-bit القديمة

---

## 🎯 إنشاء إصدار رسمي (Release)

### الطريقة الأولى: باستخدام Tag
```bash
# 1. حدّث رقم الإصدار في pubspec.yaml
version: 1.0.0+1

# 2. Commit التغييرات
git add pubspec.yaml
git commit -m "Bump version to 1.0.0"
git push origin main

# 3. أنشئ tag
git tag v1.0.0
git push origin v1.0.0

# سيتم إنشاء Release تلقائياً مع APK, AAB, Web, Windows, Linux!
```

### الطريقة الثانية: من واجهة GitHub
1. اذهب إلى **Actions → Create Release**
2. اضغط **Run workflow**
3. أدخل رقم الإصدار (مثل: `v1.0.0`)
4. اضغط **Run workflow**

---

## 📊 الفرق بين أنواع APK

| النوع | الحجم | الاستخدام |
|------|-------|----------|
| **Fat APK** | ~50-80 MB | ✅ للتوزيع المباشر (موصى به) |
| **Split APKs** | ~20-30 MB | للمتاجر الإلكترونية أو توفير المساحة |
| **AAB** | ~40-60 MB | لرفع على Google Play Store فقط |

---

## 🔍 كيفية معرفة حالة البناء

### من GitHub
1. **Actions tab** → شاهد جميع الـ builds
2. ✅ علامة خضراء = نجح
3. ❌ علامة حمراء = فشل (اضغط للتفاصيل)
4. 🟡 دائرة صفراء = جاري البناء

### إشعارات
- سيصلك إشعار email عند فشل أو نجاح البناء

---

## 🐛 حل المشاكل

### المشكلة: Build فشل
**الحلول:**
```bash
# 1. جرّب محلياً أولاً
flutter clean
flutter pub get
flutter build apk --release

# 2. إذا نجح محلياً، حدّث dependencies
flutter pub upgrade
git add pubspec.lock
git commit -m "Update dependencies"
git push
```

### المشكلة: لا أجد APK في Artifacts
**الحلول:**
- تأكد من تفعيل "Upload artifacts" عند التشغيل اليدوي
- انتظر حتى يكتمل الـ workflow (علامة ✅)
- Artifacts تُحذف تلقائياً بعد 30 يوم

---

## 💡 نصائح مهمة

1. **للتطوير اليومي**: استخدم التشغيل اليدوي (Manual run)
2. **للإصدارات الرسمية**: استخدم Tags
3. **لتوفير الوقت**: الـ build الأول بطيء (~10 دقائق)، لكن التالية أسرع (~5 دقائق) بفضل Caching
4. **لتوفير المساحة**: استخدم Split APKs
5. **للتوافق الأقصى**: استخدم Fat APK

---

## 📞 روابط مفيدة

- [دليل Workflows الشامل](.github/workflows/WORKFLOWS_GUIDE.md)
- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)

---

**آخر تحديث**: نوفمبر 2024  
**تم الإنشاء بواسطة**: Capy AI Assistant 🦫
