plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val webLabelStoreFile = System.getenv("PUNIT_WEBLABEL_STORE_FILE")
val webLabelStorePassword = System.getenv("PUNIT_WEBLABEL_STORE_PASSWORD")
val webLabelKeyAlias = System.getenv("PUNIT_WEBLABEL_KEY_ALIAS")
val webLabelKeyPassword = System.getenv("PUNIT_WEBLABEL_KEY_PASSWORD")

android {
    namespace = "com.example.punit_tablet"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.punit_tablet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Punit ERP"
    }

    signingConfigs {
        create("webLabelRelease") {
            storeFile = webLabelStoreFile?.let(::file)
            storePassword = webLabelStorePassword
            keyAlias = webLabelKeyAlias
            keyPassword = webLabelKeyPassword
        }
    }

    flavorDimensions += "edition"
    productFlavors {
        create("classic") {
            dimension = "edition"
            applicationId = "com.example.punit_tablet"
            manifestPlaceholders["appLabel"] = "Punit ERP"
            signingConfig = signingConfigs.getByName("debug")
        }
        create("webLabel") {
            dimension = "edition"
            applicationId = "com.punittechnologies.puniterp.weblabel"
            manifestPlaceholders["appLabel"] = "PUNIT ERP"
            signingConfig = signingConfigs.getByName("webLabelRelease")
        }
        create("qrDiagnostic") {
            dimension = "edition"
            applicationId = "com.punittechnologies.puniterp.weblabel.qrdiagnostic"
            manifestPlaceholders["appLabel"] = "Punit ERP QR Diagnostic"
            // Temporary diagnostic package: intentionally uses the Android
            // debug key so it never depends on or replaces the production app.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(files("libs/LabelPrinterJavaSDK.jar"))
    implementation("com.github.mik3y:usb-serial-for-android:3.10.0")
}
