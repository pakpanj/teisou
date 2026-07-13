plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.teisou.kanamaster"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.teisou.kanamaster"
        // Firebase Auth / Firestore require minSdk 23+; the `camera` plugin
        // (Cam Detector, Batch 5) requires minSdk 24+.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // google_mlkit_text_recognition only `compileOnly`-references the
    // per-script native recognizers (see its android/build.gradle) — the
    // app must add whichever ones it actually uses as a real
    // `implementation` dependency, or TextRecognizer(script: japanese)
    // crashes at runtime with NoClassDefFoundError on first use. This is
    // the bundled variant (~4MB, fully offline from install), matching
    // the exact artifact the plugin was compiled against.
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
}

flutter {
    source = "../.."
}
