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
// Older Flutter plugins (e.g. on_audio_query_android) still declare their
// package only in AndroidManifest.xml. AGP 8+ requires an explicit namespace,
// so derive it from the manifest when the plugin doesn't set one.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByName("android") as com.android.build.api.dsl.LibraryExtension
        if (android.namespace == null) {
            val manifest = file("src/main/AndroidManifest.xml")
            val manifestPackage = if (manifest.exists()) {
                Regex("""package\s*=\s*"([^"]+)"""").find(manifest.readText())?.groupValues?.get(1)
            } else {
                null
            }
            android.namespace = manifestPackage ?: project.group.toString()
        }

        // The same old plugins pin Java to an older target while Kotlin
        // defaults to the JDK version; keep Kotlin's target in sync with Java.
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(
                    android.compileOptions.targetCompatibility.toString(),
                ),
            )
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
