allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirecting build directory to prevent deep nesting issues on Windows
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

// 🛡️ Enhanced clean task to ensure the malformed NDK cache is wiped
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    // Manually delete the external build folder to clear the cache completely
    delete("${rootProject.projectDir}/../../build")
}

