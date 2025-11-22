allprojects {
    repositories {
        google()
        mavenCentral()
    }
    subprojects {
        // use Kotlin DSL version of afterEvaluate
        afterEvaluate {
            if (plugins.hasPlugin("com.android.application") ||
                plugins.hasPlugin("com.android.library")) {

                extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                    if (namespace == null) {
                        namespace = group.toString()
                    }
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
