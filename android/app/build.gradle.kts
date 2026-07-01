plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.hersite_core"
    compileSdk = 36  // <--- CAMBIADO: Borramos "flutter.compileSdkVersion" y pusimos 36 
    ndkVersion = flutter.ndkVersion

    // <--- AGREGADO: Este es el bloque para ignorar los archivos duplicados de IA
    packagingOptions {
        pickFirst("**/libonnxruntime.so")
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
isCoreLibraryDesugaringEnabled = true // <--- LLEVA "is" Y SIGNO DE IGUAL
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.hersite_core"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
    // LLEVA PARÉNTESIS Y COMILLAS DOBLES:
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") 
}