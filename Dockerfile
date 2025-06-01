# ===== Stage 1: Maven Build =====
FROM docker.io/library/maven:3.9.6-eclipse-temurin-17 AS builder

# Configure Maven to use only public repositories
RUN mkdir -p /usr/share/maven/ref/ && \
    echo '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">\
    <mirrors>\
        <mirror>\
            <id>central</id>\
            <name>Maven Central</name>\
            <url>https://repo.maven.apache.org/maven2</url>\
            <mirrorOf>central</mirrorOf>\
        </mirror>\
    </mirrors>\
    </settings>' > /usr/share/maven/ref/settings.xml

WORKDIR /build

# Copy the project definition and prefetch dependencies
COPY pom.xml .
RUN mvn -B -s /usr/share/maven/ref/settings.xml dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn -B -s /usr/share/maven/ref/settings.xml clean package -DskipTests

# ===== Stage 2: Runtime with Tomcat =====
FROM docker.io/library/tomcat:9.0.85-jdk17

# Clean default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR and extract
COPY --from=builder /build/target/java-webapp.war /tmp/
RUN unzip -q /tmp/java-webapp.war -d /usr/local/tomcat/webapps/ROOT && \
    rm -f /tmp/java-webapp.war && \
    chown -R 1001:0 /usr/local/tomcat/webapps && \
    chmod -R g+rwX /usr/local/tomcat/webapps

EXPOSE 8080
