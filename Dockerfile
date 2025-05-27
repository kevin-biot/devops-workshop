# Stage 1: Maven build
FROM maven:3.9.6-eclipse-temurin-17 as builder

WORKDIR /build
COPY . .  # ← FULL COPY to preserve structure

RUN mvn clean package

# Stage 2: Tomcat image with deployed WAR
FROM tomcat:9.0-jdk17

RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=builder /build/target/java-webapp.war /usr/local/tomcat/webapps/ROOT.war
