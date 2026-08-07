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

# ---------------------------------------------------------------------
# Added while preparing the first store release (2026-08-07).
#
# Everything above this line was written to fix an R8 failure that had
# already happened. These are the opposite: rules for libraries that
# behave the same way as the ones that broke, added before a release
# build has been run against them.
#
# The reasoning is the same each time. R8 strips what it cannot see being
# used, and none of these libraries are used in a way it can see — they
# find their classes reflectively, by name, at runtime. A missing rule
# does not fail the build; it produces an APK that installs, launches,
# and then throws NoSuchMethodException the first time the feature is
# touched. That is exactly how the ML Kit registrar bug reached a
# physical device before anyone noticed.
#
# Keeping too much costs a few KB. Keeping too little costs a release.
# ---------------------------------------------------------------------

# Google Mobile Ads: mediation adapters and the ad-format classes are
# looked up by name from server-delivered configuration.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Play Billing, behind in_app_purchase. Its listener interfaces are
# implemented by generated proxies.
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Firestore and Firebase Auth hold onto model classes and callbacks that
# only ever appear through generics.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.firebase.**

# The Play Core split-install classes Flutter's deferred-components
# support references even when no deferred component exists — a very
# common R8 "missing class" failure on Flutter release builds.
-dontwarn com.google.android.play.core.**
