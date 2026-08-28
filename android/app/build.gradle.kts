plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ally"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ally"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
