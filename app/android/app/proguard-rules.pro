# Flutter embedding / plugin registration
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Supabase / Gotrue realtime uses reflection over its models
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Flutter's deferred-components support references Play Core split-install
# classes we don't use (no dynamic feature modules in this app) — silence R8.
-dontwarn com.google.android.play.core.**
