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

// CI and demo/debug signing. Workflows decode CI_DEBUG_KEYSTORE_BASE64 to a
// temp file and set CI_DEBUG_KEYSTORE_FILE plus the password and alias env
// vars. When those are absent, debug and profile keep the Android default
// debug keystore. This does not read android/key.properties and does not
// change the Play release signingConfig below. See docs/ci-signing.md.
val ciDebugStorePath = System.getenv("CI_DEBUG_KEYSTORE_FILE")?.takeIf { it.isNotBlank() }
val ciDebugStorePassword = System.getenv("CI_DEBUG_KEYSTORE_PASSWORD")?.takeIf { it.isNotBlank() }
val ciDebugKeyAlias = System.getenv("CI_DEBUG_KEY_ALIAS")?.takeIf { it.isNotBlank() }
val ciDebugKeyPassword = System.getenv("CI_DEBUG_KEY_PASSWORD")?.takeIf { it.isNotBlank() }
val ciDebugStore = ciDebugStorePath?.let { path ->
    file(path).takeIf { it.isFile && it.length() > 0L }
}
val hasCiDebugKeystore = ciDebugStore != null &&
    ciDebugStorePassword != null &&
    ciDebugKeyAlias != null &&
    ciDebugKeyPassword != null
if (ciDebugStorePath != null && !hasCiDebugKeystore) {
    throw GradleException(
        "CI debug signing is incomplete. CI_DEBUG_KEYSTORE_FILE must point at a keystore, " +
            "and CI_DEBUG_KEYSTORE_PASSWORD, CI_DEBUG_KEY_ALIAS, and CI_DEBUG_KEY_PASSWORD must be set. " +
            "See docs/ci-signing.md."
    )
}
if (hasCiDebugKeystore) {
    logger.lifecycle("CI debug keystore: debug and profile builds use the fixed CI keystore.")
} else {
    logger.lifecycle(
        "CI debug keystore: not configured. Debug and profile builds use the default debug keystore."
    )
}

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
// Separate from DEMO_BUILD. android-smoke and demo-seed-launch pass
// DEMO_BUILD and must keep com.shradhaventures.temple. Only
// demo-app-distribution sets DEMO_APP_ID_SUFFIX (or -Pdemo_suffix=true).
val demoAppIdSuffix = dartDefines()["DEMO_APP_ID_SUFFIX"] == "true" ||
    (findProperty("demo_suffix") as? String) == "true"
// tester-checks only. The Play bundle and android-smoke do not set this.
val ciTesterChecks = (findProperty("ciTesterChecks") as? String) == "true"

// flutter build apk --release rewrites GeneratedPluginRegistrant and drops
// dev dependencies, including integration_test. Tester-checks needs that
// plugin on the engine. Play builds leave ciTesterChecks unset, so this
// file is not patched and the plugin stays off the release classpath.
fun registerCiTesterChecksPlugin() {
    val registrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
    if (!registrant.isFile) {
        throw GradleException(
            "ciTesterChecks: GeneratedPluginRegistrant.java is missing. " +
                "Flutter should have written it before compilation."
        )
    }
    val marker = "dev.flutter.plugins.integration_test.IntegrationTestPlugin"
    val text = registrant.readText()
    if (text.contains(marker)) {
        logger.lifecycle("ciTesterChecks: IntegrationTestPlugin already registered")
        return
    }
    val needle = "public static void registerWith(@NonNull FlutterEngine flutterEngine) {"
    if (!text.contains(needle)) {
        throw GradleException(
            "ciTesterChecks: GeneratedPluginRegistrant has no registerWith method"
        )
    }
    val block = """
        |    try {
        |      flutterEngine.getPlugins().add(new dev.flutter.plugins.integration_test.IntegrationTestPlugin());
        |    } catch (Exception e) {
        |      Log.e(TAG, "Error registering plugin integration_test, dev.flutter.plugins.integration_test.IntegrationTestPlugin", e);
        |    }
    """.trimMargin()
    registrant.writeText(text.replace(needle, needle + "\n" + block))
    logger.lifecycle("ciTesterChecks: registered IntegrationTestPlugin")
}

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
        if (hasCiDebugKeystore) {
            val configuredStore = ciDebugStore!!
            val configuredStorePassword = ciDebugStorePassword!!
            val configuredAlias = ciDebugKeyAlias!!
            val configuredKeyPassword = ciDebugKeyPassword!!
            getByName("debug") {
                storeFile = configuredStore
                storePassword = configuredStorePassword
                keyAlias = configuredAlias
                keyPassword = configuredKeyPassword
                // Hard-coded PKCS12. The CI debug keystore is created with
                // keytool -storetype PKCS12 (docs/ci-signing.md). Play release
                // signing does not set storeType unless key.properties does.
                storeType = "PKCS12"
            }
        }
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
        // The distributed tester APK must not install as the Play app.
        // Smoke, seed-launch, and the Play AAB do not set this flag.
        if (demoAppIdSuffix) {
            applicationIdSuffix = ".demo"
        }
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Instrumentation runner for integration_test. Release and debug
        // app builds do not execute it.
        testInstrumentationRunner =
            "com.shradhaventures.temple.TesterChecksRunner"
        manifestPlaceholders["appLabel"] = if (demoAppIdSuffix) {
            "Temple Directory India Demo"
        } else {
            "Temple Directory India"
        }
        manifestPlaceholders["admobAppId"] = if (demoBuild) {
            "ca-app-pub-3940256099942544~3347511713"
        } else {
            "ca-app-pub-7782159535499045~4640625144"
        }
    }

    buildTypes {
        debug {
            // tester-checks installs the release APK and this debug
            // androidTest APK. Android rejects instrumentation when the
            // signatures differ. -PciTesterChecks=true signs the test APK
            // with the release key. Local debug builds leave this unset.
            if (ciTesterChecks && hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Flutter minifies release. Keep the instrumentation classes when
            // this APK is the tester-checks target. Play builds leave the
            // property unset, so they do not add this file.
            if (ciTesterChecks) {
                proguardFiles.add(file("ci-tester-checks-rules.pro"))
            }
        }
    }
}

afterEvaluate {
    if (hasCiDebugKeystore) {
        extensions.configure<com.android.build.api.dsl.ApplicationExtension>("android") {
            buildTypes.findByName("profile")?.let { profile ->
                profile.signingConfig = signingConfigs.getByName("debug")
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
    // flutter build appbundle runs bundleRelease. The demo APK is
    // assembleRelease and may use the suffix. A Play bundle must not.
    val playBundleRequested = allTasks.any { task ->
        task.project == project && task.name == "bundleRelease"
    }
    if (playBundleRequested && demoAppIdSuffix) {
        throw GradleException(
            "Play app bundle must stay com.shradhaventures.temple. " +
                "DEMO_APP_ID_SUFFIX and -Pdemo_suffix apply only to the App Distribution demo APK."
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // integration_test exports runner 1.2+, rules 1.2+, and espresso 3.3+
    // onto the app classpath. AGP then locks androidTest to those resolved
    // versions (runner 1.3.0, rules 1.2.0, espresso 3.3.0).
    androidTestImplementation("androidx.test:runner:1.3.0")
    androidTestImplementation("androidx.test:rules:1.2.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.3.0")
    if (ciTesterChecks) {
        // The debug app already contains these, so the androidTest APK does
        // not. The release app is minified and omits the dev-dependency
        // plugin, so instrumentation cannot load AndroidJUnitRunner unless
        // this APK ships the classes.
        releaseImplementation("androidx.test:runner:1.3.0")
        releaseImplementation("androidx.test:rules:1.2.0")
        releaseImplementation("androidx.test.espresso:espresso-core:3.3.0")
    }
}

if (ciTesterChecks) {
    afterEvaluate {
        val integration = rootProject.findProject(":integration_test")
            ?: throw GradleException(
                "ciTesterChecks requires the :integration_test Android project"
            )
        dependencies.add("releaseApi", integration)
    }
    // Patch immediately before javac. Flutter has already rewritten the
    // registrant for release by the time Gradle compiles it.
    tasks.configureEach {
        if (name == "compileReleaseJavaWithJavac") {
            doFirst { registerCiTesterChecksPlugin() }
        }
    }
}
