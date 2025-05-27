FROM maven:3.9.6-eclipse-temurin-17 as builder

WORKDIR /build

# Copy pom.xml first for better layer caching
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Tomcat runtime
FROM tomcat:9.0-jdk17

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file
COPY --from=builder /build/target/java-webapp.war /usr/local/tomcat/webapps/ROOT.war

# Optional: Set proper permissions for OpenShift
RUN chmod -R g+rwx /usr/local/tomcat/webapps/ && \
    chgrp -R 0 /usr/local/tomcat/webapps/

# Expose port
EXPOSE 8080
