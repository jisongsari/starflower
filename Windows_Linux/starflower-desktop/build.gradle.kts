import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    kotlin("jvm") version "2.0.20"
    id("org.jetbrains.compose") version "1.7.0"
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20"
}

group = "com.songsari.starflower"
version = "1.0.0"

repositories {
    google()
    mavenCentral()
    maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")
}

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation(compose.materialIconsExtended)
    implementation(compose.animation)

    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.squareup.retrofit2:converter-moshi:2.11.0")
    implementation("com.squareup.moshi:moshi-kotlin:1.15.1")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-swing:1.9.0")
}

kotlin {
    jvmToolchain(17)
}

compose.desktop {
    application {
        mainClass = "com.songsari.starflower.MainKt"

        nativeDistributions {
            // 이 OS에서 빌드하면 이 OS용 포맷만 만들어진다.
            // Windows 에서 실행 → msi, 리눅스(우분투 등)에서 실행 → deb
            targetFormats(TargetFormat.Msi, TargetFormat.Deb, TargetFormat.Rpm)
            packageName = "Starflower"
            packageVersion = "1.0.0"
            description = "오늘 밤 별 관측 지수"
            copyright = "© 2026 양지성"
            vendor = "songsari"

            windows {
                menuGroup = "Starflower"
                perUserInstall = true
                shortcut = true
                dirChooser = true
            }
            linux {
                packageName = "starflower"
                debMaintainer = "songsari@example.com"
                menuGroup = "Utility"
                appCategory = "Utility"
            }
        }
    }
}
