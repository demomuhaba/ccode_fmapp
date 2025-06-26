## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## Dart
-keep class com.google.dart.** { *; }

## Supabase
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }

## Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

## Isar Database
-keep class io.isar.** { *; }

## Local Auth
-keep class androidx.biometric.** { *; }

## File operations
-keep class java.io.** { *; }

## JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

## Keep model classes
-keep class * extends java.io.Serializable { *; }

## Don't warn about platform differences
-dontwarn java.lang.invoke.StringConcatFactory