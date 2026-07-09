# Moshi
-keep class com.songsari.starflower.data.** { *; }
-keepclassmembers class * {
    @com.squareup.moshi.Json *;
}
-keep class kotlin.Metadata { *; }
