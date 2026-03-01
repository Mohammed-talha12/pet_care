plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pet_care"
    compileSdk = flutter.compileSdkVersion
    
    // ✅ Keeps your stable NDK fix
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ✅ Fixes Line 22: Migration to compilerOptions DSL
    kotlinOptions {
        @Suppress("DEPRECATION")
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.pet_care"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // ✅ Fixes Lines 30 & 31: Uses the correct Flutter references
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}