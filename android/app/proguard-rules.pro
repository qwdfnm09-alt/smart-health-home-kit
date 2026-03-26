# Keep all flutter_blue_plus classes (avoid stripping BLE logic)
-keep class com.pauldemarco.flutter_blue_plus.** { *; }

# Keep app code
-keep class com.example.smart_health_home_kit.** { *; }

# Keep all Flutter engine and plugin registration classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.plugins.** { *; }

# Keep lifecycle & protobuf dependencies used internally
-keep class androidx.lifecycle.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep Bluetooth classes
-keep class android.bluetooth.** { *; }

# Keep Dart/Flutter JNI bridge
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Keep reactive streams
-keep class io.reactivex.** { *; }
-dontwarn io.reactivex.**

# Keep FlutterBluePlus classes (prevent stripping/obfuscation)
-keep class com.pauldemarco.flutterblueplus.** { *; }
-keep interface com.pauldemarco.flutterblueplus.** { *; }


# Keep annotations
-keepattributes *Annotation*



