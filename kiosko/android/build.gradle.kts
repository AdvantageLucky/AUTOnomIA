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
subprojects {
    project.evaluationDependsOn(":app")
}

// tflite_flutter fija Java 11 para su propio módulo pero no fija el jvmTarget de
// Kotlin, así que Gradle usa el JDK del host (21 aquí) y falla por inconsistencia
// Java/Kotlin. Forzamos el jvmTarget de Kotlin de ESE módulo a 11 para que
// coincida con su propio Java — sin tocar :app ni otros plugins. No usamos
// afterEvaluate/subprojects (el evaluationDependsOn de arriba ya deja algunos
// proyectos evaluados antes de tiempo); tasks.withType(...).configureEach es
// seguro de registrar en cualquier momento.
project(":tflite_flutter").tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

// vosk_flutter_service fija compileSdk 33 en su propio build.gradle, pero
// sus propias dependencias transitivas (androidx.appcompat 1.7.0 y otras)
// exigen compilar contra SDK 34+ -- se sube aquí al mismo compileSdk que
// usa el resto del proyecto (36, ya instalado localmente), sin tocar el
// paquete en pub-cache.
project(":vosk_flutter_service").afterEvaluate {
    extensions.configure<com.android.build.gradle.LibraryExtension> {
        compileSdk = 36
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
