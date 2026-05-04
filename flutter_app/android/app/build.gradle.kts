plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.jyotishai.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = "11" }
    defaultConfig {
        applicationId = "com.jyotishai.app"
        minSdk = 21; targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false  // must match isMinifyEnabled
        }
    }
}
flutter { source = "../.." }
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}
