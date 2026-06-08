import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load release-signing credentials from key.properties (not committed). If the
// file is absent (fresh clone, CI without secrets), `signingConfigs.release`
// stays empty and the release build falls back to debug signing so the build
// still succeeds — only sideload-able builds need the real keystore.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        FileInputStream(f).use { load(it) }
    }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.relmarzouki.expensy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.relmarzouki.expensy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // Keep R8 OFF. AGP 9 flipped the release default for `isMinifyEnabled`
            // to true, and R8 strips WorkManager's reflectively-instantiated Room
            // database (pulled in transitively by the home_widget plugin), which
            // crashes the app at startup with:
            //   "Failed to create an instance of androidx.work.impl.WorkDatabase".
            // Flutter already obfuscates Dart via `--obfuscate --split-debug-info`,
            // and R8 has historically broken reflection-based plugins. Only enable
            // it after testing the APK end-to-end with keep rules in
            // proguard-rules.pro covering every package that complains (WorkManager,
            // Room, and friends).
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
