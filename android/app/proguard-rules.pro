# Flutter / Play Store release ProGuard rules

# slf4j is referenced transitively (e.g. via pusher_channels_flutter) but the
# impl binding class is optional and not present at runtime. Safe to ignore.
-dontwarn org.slf4j.**

# Keep Flutter's generated plugin registrant and embedding classes.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
