plugins {
    id("application")
    kotlin("jvm") version "2.4.20"
}

application {
    mainClass.set("MainKt")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.seo4d696b75.diagram:station:0.3.0")
}

kotlin {
    jvmToolchain(17)
}