# R8/ProGuard rules. Active only when `isMinifyEnabled = true` in build.gradle.kts.
# Flutter's Gradle plugin already injects the rules its own engine needs; these
# are belt-and-suspenders for libraries that have caused issues in the wild.

# Reflection-using JSON libraries (kept defensively; safe no-op if unused).
-keep class * extends com.google.gson.TypeAdapter
-keepattributes Signature
-keepattributes *Annotation*

# Kotlin reflection metadata (Hive/freezed code-gen does not need this,
# but a future package might).
-keep class kotlin.Metadata { *; }

# Keep line numbers — readable stack traces in crash reports.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
