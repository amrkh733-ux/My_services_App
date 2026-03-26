// android/build.gradle.kts

plugins {
    // استخدام نسخة مستقرة من google-services لتجنب التعارض
    id("com.google.gms.google-services") version "4.3.15" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.1")
        classpath("com.google.gms:google-services:4.3.15")
        // إضافة أي classpath آخر يحتاجه المشروع هنا
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// إعادة تحديد مجلد build خارجي (اختياري، حسب مشروعك)
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

// مهمة تنظيف المشروع
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}