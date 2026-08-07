import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing, read from android/key.properties.
//
// That file holds a password and is git-ignored, so it exists only on a
// developer's machine or is written by the build machine — Codemagic
// creates it from the keystore uploaded to its own settings. Nothing
// secret lives in this repository.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()

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

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signed with the real key when there is one, and with the
            // debug key otherwise so `flutter run --release` still works
            // on a machine that has no keystore.
            //
            // **The debug fallback is what shipped here for months**, left
            // over from `flutter create`, and it is not a harmless
            // default: Play Console refuses the upload outright with "You
            // uploaded an APK or Android App Bundle that was signed in
            // debug mode", and there is nothing in a local build that
            // hints at it. Hence the message below — a store-bound build
            // that quietly falls back should be impossible to miss.
            if (!hasReleaseKeystore) {
                logger.warn(
                    "*** android/key.properties not found — this release " +
                        "build is signed with the DEBUG key and Play Console " +
                        "will reject it. ***"
                )
            }
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
