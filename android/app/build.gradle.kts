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

// Play upload key. android/key.properties is gitignored. Debug builds do not
// read it. A release build fails when it is missing or incomplete instead of
// signing with the debug keystore. See docs/android-play-internal-test.md.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun keystoreProperty(name: String): String? =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }

val releaseStoreFilePath = keystoreProperty("storeFile")
val releaseStorePassword = keystoreProperty("storePassword")
val releaseKeyAlias = keystoreProperty("keyAlias")
val releaseKeyPassword = keystoreProperty("keyPassword")
val missingSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .filter { keystoreProperty(it) == null }
val releaseStoreFile = releaseStoreFilePath?.let { file(it) }
val hasReleaseKeystore = keystorePropertiesFile.isFile &&
    missingSigningKeys.isEmpty() &&
    releaseStoreFile?.isFile == true

fun releaseSigningError(): String {
    val problem = when {
        !keystorePropertiesFile.exists() ->
            "android/key.properties is missing."
        missingSigningKeys.isNotEmpty() ->
            "android/key.properties must define ${missingSigningKeys.joinToString(", ")}."
        else ->
            "storeFile does not exist: $releaseStoreFilePath (resolved from the android/app module)."
    }
    return """
        Release signing is not configured. $problem
        Create gitignored android/key.properties with storeFile, storePassword, keyAlias, and keyPassword.
        See docs/android-play-internal-test.md.
        Debug builds do not need this file. Refusing to sign a release build with the debug keystore.
        """.trimIndent()
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
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseRequested = allTasks.any { task ->
        task.project == project && task.name.endsWith("Release")
    }
    if (releaseRequested && !hasReleaseKeystore) {
        throw GradleException(releaseSigningError())
    }
}

flutter {
    source = "../.."
}
