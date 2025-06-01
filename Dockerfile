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
COPY pom.xml .
# Run with custom settings to ensure public repo usage
RUN mvn -B -s /usr/share/maven/ref/settings.xml dependency:go-offline

COPY src ./src
RUN mvn -B -s /usr/share/maven/ref/settings.xml clean package -DskipTests

FROM tomcat:9.0-jdk17
RUN rm -rf /usr/local/tomcat/webapps/*

# Manually explode WAR with proper permissions (OpenShift compatible)
COPY --from=builder /build/target/java-webapp.war /tmp/
RUN unzip -q /tmp/java-webapp.war -d /usr/local/tomcat/webapps/ROOT && \
    rm -f /tmp/java-webapp.war && \
    chown -R 1001:0 /usr/local/tomcat/webapps && \
    chmod -R g+rwX /usr/local/tomcat/webapps

EXPOSE 8080
