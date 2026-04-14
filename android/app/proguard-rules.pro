# Keep Hive and its generated adapters
-keep class io.hive.*** { *; }
-keep class * extends io.hive.TypeAdapter { *; }
-keep class * extends io.hive.HiveObject { *; }

# Keep your specific model classes and their generated adapters
-keep class com.smarthealth.homekit.models.** { *; }
-keep class com.smarthealth.homekit.models.adapters.** { *; }

# Prevent obfuscation of Hive internal methods
-keepclassmembers class * extends io.hive.TypeAdapter {
    public <init>(...);
}

# Keep Bluetooth classes
-keep class android.bluetooth.** { *; }
-keep class com.pauldemarco.flutter_blue_plus.** { *; }

# Google Generative AI Support
-keep class com.google.ai.client.generativeai.** { *; }

# Flutter Local Notifications & Alarms
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.NotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# PDF & Printing support
-keep class com.shockwave.pdfium.** { *; }
-keep class com.shockwave.pdfium.PdfiumCore { *; }
-keep class com.shockwave.pdfium.util.** { *; }
-keep class com.shockwave.pdfium.util.Size { *; }
-keep class com.shockwave.pdfium.util.SizeF { *; }

# Common JSON serialization (Required for AI and HTTP)
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
-keep class com.google.gson.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# Firebase Crashlytics and Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Speech to Text support
-keep class com.csdcorp.speech_to_text.** { *; }



