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

subprojects {
    if (!state.executed) {
        afterEvaluate {
            val android = project.extensions.findByName("android") ?: return@afterEvaluate
            val methods = android.javaClass.methods
            val compileSdkVersion = methods.firstOrNull {
                it.name == "compileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Integer::class.java)
            }
            try {
                if (compileSdkVersion != null) {
                    compileSdkVersion.invoke(android, 36)
                } else {
                    methods.firstOrNull {
                        it.name == "setCompileSdk" &&
                            it.parameterTypes.size == 1 &&
                            (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == Integer::class.java)
                    }?.invoke(android, 36)
                }
            } catch (_: Exception) {
                // compileSdk was already locked by another plugin; leave it unchanged.
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
