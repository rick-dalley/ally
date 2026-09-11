import java.io.FileInputStream
import java.util.Properties

// Release signing. The keystore file and its passwords never live in the repo —
// android/key.properties (gitignored) names where they are, and holds nothing but
// a path and three secrets. See tool/README-signing.md.
//
// Without that file the release build falls back to the debug key so a fresh clone
// still builds and `flutter run --release` still works. Play rejects a debug-signed
// bundle, so that fallback can never be uploaded by accident — but it does warn,
// because a silent fallback is how you discover the problem at upload time instead.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cwicare.ally"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.cwicare.ally"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("upload") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("upload")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found — signing this release " +
                    "with the debug key. Play will reject the result; see " +
                    "tool/README-signing.md."
                )
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Acuitage and Progressor crashed on launch with MainActivity stripped by
            // R8 (they had no proguardFiles at all, so no keep rules applied). This
            // app only survived by luck — the default optimize file above happens to
            // keep Activity subclasses. Disabling minification outright removes that
            // fragility for all three apps rather than relying on it implicitly.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // The Data Layer API (MessageClient/NodeClient) MainActivity.kt's Wear OS bridge
    // uses to talk to a paired wear_os watch app.
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
}

flutter {
    source = "../.."
}
