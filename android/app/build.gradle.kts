plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lorekeeper.app"
    compileSdk = (findProperty("android.compileSdk") as String?)?.toInt()
    ndkVersion = findProperty("android.ndkVersion") as String

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // A unique Application ID is required for the Google Play Store.
        applicationId = "com.lorekeeper.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = (findProperty("android.minSdk") as String?)?.toInt()
        targetSdk = (findProperty("android.targetSdk") as String?)?.toInt()
        versionCode = (findProperty("android.versionCode") as String?)?.toInt()
        versionName = findProperty("android.versionName") as String
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
