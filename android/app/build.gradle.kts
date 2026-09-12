import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.github.triplet.play")
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

/** Prefer local.properties; fall back to Flutter `.env` so one key works for Dart + Android Maps. */
fun resolveGoogleMapsApiKey(): String {
    localProperties.getProperty("GOOGLE_MAPS_API_KEY")?.trim()?.takeIf { it.isNotEmpty() }?.let {
        return it
    }
    val envFile = rootProject.file("../.env")
    if (envFile.exists()) {
        envFile.readLines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.startsWith("GOOGLE_MAPS_API_KEY=")) {
                return trimmed.removePrefix("GOOGLE_MAPS_API_KEY=").trim()
            }
        }
    }
    return ""
}

val googleMapsApiKey = resolveGoogleMapsApiKey()

val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) {
        file.inputStream().use { load(it) }
    }
}

android {
    namespace = "br.com.conectenis.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "br.com.conectenis.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use the release signing config if key.properties is present;
            // otherwise fall back to debug keys so `flutter run --release` still works.
            signingConfig = if (rootProject.file("key.properties").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// --- Google Play publishing (Gradle Play Publisher) ---
// Credentials are resolved, in order, from:
//   1. `playServiceAccountJson` in android/key.properties (local, git-ignored)
//   2. the PLAY_SERVICE_ACCOUNT_JSON environment variable
//   3. android/play-service-account.json (git-ignored)
// If none is found the plugin stays inert so normal builds are unaffected.
val playCredentialsPath: String? =
    keystoreProperties.getProperty("playServiceAccountJson")
        ?: System.getenv("PLAY_SERVICE_ACCOUNT_JSON")
        ?: rootProject.file("play-service-account.json").takeIf { it.exists() }?.path

play {
    if (playCredentialsPath != null && file(playCredentialsPath).exists()) {
        serviceAccountCredentials.set(file(playCredentialsPath))
    }
    // Override with -Pplay.track=... (e.g. alpha, beta, production).
    track.set(providers.gradleProperty("play.track").orElse("internal"))
    defaultToAppBundles.set(true)
    // Upload the artifact produced by `flutter build appbundle` instead of letting
    // Gradle rebuild it. The deploy script passes -Pplay.artifactDir=... to enable this.
    providers.gradleProperty("play.artifactDir").orNull?.let { artifactDir.set(file(it)) }
}
