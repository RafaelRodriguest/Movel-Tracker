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

# flutter_secure_storage uses androidx.security.crypto (Tink) via reflection
# for EncryptedSharedPreferences — without these, R8 strips classes it needs
# at runtime and persistSession()/read() throw, breaking login silently.
-keep class com.google.crypto.tink.** { *; }
-keep interface com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.google.errorprone.annotations.**
