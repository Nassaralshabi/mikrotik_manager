import java.util.Properties
import java.io.FileInputStream
import java.io.File
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ============================================================
//  Signing — reads from either CI env vars or local key.properties
//  Priority:
//   1) CI env vars: KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
//   2) Local file: android/key.properties
//   3) Fallback: debug signing
// ============================================================
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val isCiSigning = System.getenv("KEYSTORE_PATH")?.isNotEmpty() == true
val hasKeyProperties = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.simpurrapps.ommon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.2.12479018"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Note: kotlinOptions { jvmTarget = ... } is deprecated in Kotlin 2.x.
    // Use the new compilerOptions DSL instead. The JvmTarget enum is imported above.
    // This avoids the deprecation warning that was breaking CI compilation.
    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.simpurrapps.ommon"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keep only Arabic + English resources.
        // resourceConfigurations is deprecated; use androidResources.localeFilters instead.
        // (see https://developer.android.com/build/manage-manifests)
    }

    androidResources {
        localeFilters += listOf("ar", "en")
    }

    signingConfigs {
        create("release") {
            if (isCiSigning) {
                // CI: env vars come from GitHub Secrets.
                // KEYSTORE_PATH is relative to repo root, so use rootProject.projectDir.parentFile
                val repoRoot = rootProject.projectDir.parentFile
                storeFile = File(repoRoot, System.getenv("KEYSTORE_PATH"))
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            } else if (hasKeyProperties) {
                // Local: from android/key.properties
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                val keystoreFile = keystoreProperties.getProperty("storeFile")
                if (keystoreFile != null) {
                    storeFile = file(keystoreFile)
                }
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if available, else debug
            signingConfig = if (isCiSigning || hasKeyProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Enable code shrinking and obfuscation
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
