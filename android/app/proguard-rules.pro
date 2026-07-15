# google_mlkit_text_recognition's native bridge (TextRecognizer.kt)
# references Chinese/Devanagari/Korean recognizer option classes
# unconditionally in a `when` block, but this app only bundles the
# Japanese language pack (see the mlkit dependency in build.gradle.kts).
# Those branches are unreachable — Cam Detector only ever requests
# TextRecognitionScript.japanese — so R8 can be told to ignore the
# missing classes instead of the app bundling unused language packs.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.korean.**

# androidx.work's internal WorkDatabase (a Room database) is located at
# startup via its Room-generated WorkDatabase_Impl subclass, instantiated
# reflectively. WorkManager's own consumer rules only keep the class shell
# (`-keep class * extends androidx.room.RoomDatabase`, no member body),
# not the generated subclass's constructor, which R8 otherwise strips as
# apparently unused — this crashed every app launch in release mode with
# "Failed to create an instance of androidx.work.impl.WorkDatabase" until
# added (confirmed via build/app/outputs/mapping/release/configuration.txt
# and a physical-device logcat capture).
-keep class **_Impl { *; }
-keep class **_Impl$* { *; }

# Firebase and ML Kit's on-device libraries (ML Kit's vision/text registrars
# are discovered through Firebase's own component system — confirmed via
# `javap` that CommonComponentRegistrar/VisionCommonRegistrar both
# `implements com.google.firebase.components.ComponentRegistrar`) find their
# ComponentRegistrar implementations reflectively via a manifest-declared
# class list, then call the no-arg constructor directly. Without a keep
# rule R8 strips that constructor as apparently unused, so every registrar
# (mlkit's Common/VisionCommon/Text registrars, Firebase App Check's two
# registrars) failed with NoSuchMethodException on <init> at startup. This
# didn't crash the app, but it meant ML Kit's text-vision components never
# registered, so Cam Detector's Japanese recognizer failed on every single
# frame with "ImageError: Getting Image failed" (NullPointerException) —
# confirmed via a physical-device logcat capture reproducing the "Model
# pengenalan teks belum siap" warning banner from a clean process start.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
