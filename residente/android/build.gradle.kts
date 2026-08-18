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
// Kotlin, así que Gradle usa el JDK del host y falla por inconsistencia
// Java/Kotlin. Forzamos el jvmTarget de Kotlin de ESE módulo a 11 para que
// coincida con su propio Java — sin tocar :app ni otros plugins. Mismo fix
// que ya existe en kiosko/android/build.gradle.kts (misma dependencia).
project(":tflite_flutter").tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
