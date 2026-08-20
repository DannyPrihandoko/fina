buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Paksa semua subproject (termasuk plugin pihak ketiga seperti `home_widget`) pakai
// JVM target 11 yang sama dengan modul app (lihat android/app/build.gradle.kts).
// Tanpa ini, plugin yang tidak set jvmTarget sendiri jatuh ke default 1.8, dan build
// gagal dengan "Cannot inline bytecode built with JVM target 11 into bytecode that
// is being built with JVM target 1.8" begitu plugin itu bergantung pada library
// (mis. androidx.glance) yang inline function-nya dikompilasi di target 11.
// HARUS didaftarkan sebelum `evaluationDependsOn(":app")` di bawah — itu memaksa
// project :app langsung dievaluasi, dan afterEvaluate() akan error kalau didaftarkan
// setelah project tersebut sudah selesai dievaluasi.
subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "11"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
