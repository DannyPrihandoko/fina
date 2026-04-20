## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.runtime.view.FlutterView { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## Google Play Services & Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**

## Flutter & Plugins
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.plugin.platform.**

## Standard Java/Android
-keepattributes Signature, *Annotation*, EnclosingMethod
-dontwarn java.lang.invoke.*
-dontwarn **.CustomTabsServiceConnection
-ignorewarnings
