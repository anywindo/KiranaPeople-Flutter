# Flutter Wrapper & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# SharedPreferences plugin (Pigeon & Kotlin coroutines)
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }

# All Flutter plugins
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }

# Kotlin coroutines and reflection
-keepattributes *Annotation*,InnerClasses,Signature,EnclosingMethod,Exceptions
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
