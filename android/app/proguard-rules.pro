# Flutter/R8 rules for google_mlkit_text_recognition

-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }

# General ML Kit rules
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**
-dontwarn com.google.mlkit.common.**
