plugins {
    id("java")
    id("application")
}

application {
    mainClass.set("jp.seo.station.app.DiagramCalc")
}

repositories {
    maven {
        name = "GitHubPackages"
        url = uri("https://maven.pkg.github.com/Seo-4d696b75/diagram")
        credentials {
            username = System.getenv("GITHUB_PACKAGE_USERNAME")
            password = System.getenv("GITHUB_PACKAGE_TOKEN")
        }
    }
    mavenCentral()
}

dependencies {
    implementation("com.github.seo4d696b75:diagram:0.1.2")
}