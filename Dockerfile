FROM maven:3.9.6-eclipse-temurin-17 as builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM tomcat:9.0-jdk17
RUN rm -rf /usr/local/tomcat/webapps/*

# Manually explode WAR with proper permissions
COPY --from=builder /build/target/java-webapp.war /tmp/
RUN unzip -q /tmp/java-webapp.war -d /usr/local/tomcat/webapps/ROOT && \
    rm -f /tmp/java-webapp.war && \
    chown -R 1001:0 /usr/local/tomcat/webapps && \
    chmod -R g+rwX /usr/local/tomcat/webapps

EXPOSE 8080
