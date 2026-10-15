import java.util.Base64
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
// Optional. Play key.properties omits this and keeps the AGP default.
// The demo distribution workflow sets PKCS12 for its demo keystore.
val releaseStoreType = keystoreProperty("storeType")
val missingSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .filter { keystoreProperty(it) == null }
val releaseStoreFile = releaseStoreFilePath?.let { file(it) }
val hasReleaseKeystore = keystorePropertiesFile.isFile &&
    missingSigningKeys.isEmpty() &&
    releaseStoreFile?.isFile == true

// Flutter passes `--dart-define` as comma-separated base64 `-Pdart-defines`.
// DEMO_BUILD=true selects Google's test AdMob app id (KAN-89). Unit ids are
// chosen in Dart (`lib/services/ad_unit_ids.dart`); keep the two app id
// strings below in sync with that file.
fun dartDefines(): Map<String, String> {
    val raw = (findProperty("dart-defines") as? String)?.trim().orEmpty()
    if (raw.isEmpty()) return emptyMap()
    val out = linkedMapOf<String, String>()
    for (encoded in raw.split(',')) {
        val decoded = runCatching {
            String(Base64.getDecoder().decode(encoded.trim()), Charsets.UTF_8)
        }.getOrNull() ?: continue
        val eq = decoded.indexOf('=')
        if (eq <= 0) continue
        out[decoded.substring(0, eq)] = decoded.substring(eq + 1)
    }
    return out
}

val demoBuild = dartDefines()["DEMO_BUILD"] == "true"

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
                if (releaseStoreType != null) {
                    storeType = releaseStoreType
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.shradhaventures.temple"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = if (demoBuild) {
            "ca-app-pub-3940256099942544~3347511713"
        } else {
            "ca-app-pub-7782159535499045~4640625144"
        }
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
