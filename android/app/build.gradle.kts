plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // Plugin de servicios de Google
    id("dev.flutter.flutter-gradle-plugin") // Flutter debe ir después
}

android {
    namespace = "com.example.easyexpres"
    compileSdk = flutter.compileSdkVersion

    // ✅ NDK actualizado
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.easyexpres"

        // ✅ minSdk actualizado a 23 por requerimiento de firebase-auth 23.x
        minSdk = 23
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.15.0"))

    // ✅ Servicios Firebase utilizados
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}

// ✅ Aplica el plugin de Google Services al final
apply(plugin = "com.google.gms.google-services")
