# ----------------------------------
# 1. Flutter & Plugins (Required)
# ----------------------------------
-keep class io.flutter.** { *; }
-keep class androidx.lifecycle.** { *; }

# Keep MethodChannel
-keep class io.flutter.plugin.common.** { *; }

# ----------------------------------
# 2. Notifications & Foreground
# ----------------------------------
# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }

# Required for notification actions & receivers
-keep class me.carda.awesome_notifications.notifications.receivers.** { *; }
-keep class me.carda.awesome_notifications.notifications.services.** { *; }


# AndroidX Media (for notification & audio background)
-keep class androidx.media.** { *; }
-dontwarn androidx.media.**

# NotificationCompat
-keep class androidx.core.app.NotificationCompat** { *; }

# ----------------------------------
# 3. Play Core / Dynamic Features
# ----------------------------------
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# ----------------------------------
# 4. WorkManager (optional)
# ----------------------------------
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# ----------------------------------
# 5. Legacy AndroidX Support (avoid lint)
# ----------------------------------
-dontwarn android.support.**
-dontwarn android.support.v4.**

# ----------------------------------
# 6. Constructor Rule (Fix "Unresolved class name" IDE warnings)
# ----------------------------------
-keepclassmembers class * {
    public <init>(...);
}
