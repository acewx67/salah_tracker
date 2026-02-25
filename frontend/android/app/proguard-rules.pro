# Flutter Local Notifications ProGuard rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep public class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter

# GSON type parameters
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
