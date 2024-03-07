import java.io.FileInputStream
import java.util.Properties

plugins {
    id("java")
    id("application")
}

application {
    mainClass.set("jp.seo.station.app.MainKt")
}

val props = Properties().apply {
    val file = project.file("credentials.properties")
    if (file.exists()) {
        file.inputStream().use {
            load(it)
        }
    }
}

repositories {
    maven {
        name = "GitHubPackages"
        url = uri("https://maven.pkg.github.com/Seo-4d696b75/diagram")
        credentials {
            // read .properties file in local, or env variables in GitHub Action
            username = props.getProperty("username") ?: System.getenv("GITHUB_PACKAGE_USERNAME")
            password = props.getProperty("token") ?: System.getenv("GITHUB_PACKAGE_TOKEN")
        }
    }
    mavenCentral()
}

dependencies {
    implementation("com.github.seo4d696b75:diagram:0.2.2")
}