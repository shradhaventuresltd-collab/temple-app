import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Play upload key. android/key.properties is gitignored and is not required
// for debug or for a local release assemble. When it is absent, release stays
// on the debug keystore so development still builds; that artifact is not a
// Play upload. See docs/android-play-internal-test.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun keystoreProperty(name: String): String? =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }

val releaseStoreFilePath = keystoreProperty("storeFile")
val releaseStorePassword = keystoreProperty("storePassword")
val releaseKeyAlias = keystoreProperty("keyAlias")
val releaseKeyPassword = keystoreProperty("keyPassword")
if (hasReleaseKeystore) {
    val missingKeys = listOf(
        "storeFile" to releaseStoreFilePath,
        "storePassword" to releaseStorePassword,
        "keyAlias" to releaseKeyAlias,
        "keyPassword" to releaseKeyPassword,
    ).filter { it.second.isNullOrBlank() }.map { it.first }
    require(missingKeys.isEmpty()) {
        "android/key.properties must define ${missingKeys.joinToString(", ")}."
    }
}

android {
    namespace = "com.shradhaventures.temple"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                // Resolved from android/app, so ../upload-keystore.jks is android/upload-keystore.jks.
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
            }
        }
    }

    defaultConfig {
        applicationId = "com.shradhaventures.temple"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
