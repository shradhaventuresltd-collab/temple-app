# tester-checks release APK only. Nothing in the app references these types;
# the androidTest APK does, and R8 cannot see that.
-keep class androidx.test.** { *; }
-keep class androidx.test.espresso.** { *; }
-keep class androidx.test.runner.** { *; }
-keep class androidx.test.rule.** { *; }
-keep class junit.** { *; }
-keep class org.junit.** { *; }
-keep class dev.flutter.plugins.integration_test.** { *; }
-keep class com.shradhaventures.temple.TesterChecksRunner { *; }
-keep class com.shradhaventures.temple.MainActivityTest { *; }
-dontwarn androidx.test.**
-dontwarn androidx.test.espresso.**
-dontwarn junit.**
-dontwarn org.junit.**
-dontwarn com.google.common.**
