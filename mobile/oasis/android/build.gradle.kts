import com.android.build.gradle.BaseExtension
import org.gradle.api.Project
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    subprojects {
        afterEvaluate {
            if (plugins.hasPlugin("com.android.application") ||
                plugins.hasPlugin("com.android.library")
            ) {
                extensions.findByName("android")?.let { ext ->
                    (ext as BaseExtension).apply {
                        compileSdkVersion(36)
                        buildToolsVersion = "36.0.0"

                        if (namespace == null) {
                            namespace = group.toString()
                        }
                    }
                }
            }

            buildDir = file("${rootProject.buildDir}/$name")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()

rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(name)
    layout.buildDirectory.value(newSubprojectBuildDir)
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
