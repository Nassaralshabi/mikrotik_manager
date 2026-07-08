# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn io.flutter.embedding.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Dio
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keepattributes Signature
-keepattributes Exceptions
-keep class io.reactivex.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Crypto
-keep class java.security.** { *; }
-keep class javax.crypto.** { *; }

# ============================================================
# ML Kit text recognition
# The google_mlkit_text_recognition Flutter plugin references
# optional Chinese / Japanese / Korean / Devanagari recognizer
# classes that are only bundled when those language packs are
# added as dependencies. This app uses the Latin script
# recognizer only, so R8 fails with "Missing class" errors
# during minification. Suppress those warnings.
# (See https://github.com/flutter-ml/google_ml_kit_flutter/issues/239)
# ============================================================
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# Keep ML Kit base text recognizer classes that ARE bundled
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-keep class com.google.android.gms.vision.text.** { *; }
