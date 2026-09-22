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
val releaseStoreFilePath: String?
val releaseStorePassword: String?
val releaseKeyAlias: String?
val releaseKeyPassword: String?
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    val missingKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    require(missingKeys.isEmpty()) {
        "android/key.properties must define ${missingKeys.joinToString(", ")}."
    }
    releaseStoreFilePath = keystoreProperties.getProperty("storeFile")
    releaseStorePassword = keystoreProperties.getProperty("storePassword")
    releaseKeyAlias = keystoreProperties.getProperty("keyAlias")
    releaseKeyPassword = keystoreProperties.getProperty("keyPassword")
} else {
    releaseStoreFilePath = null
    releaseStorePassword = null
    releaseKeyAlias = null
    releaseKeyPassword = null
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
