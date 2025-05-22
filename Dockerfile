# Build stage
FROM maven:3.8-openjdk-11 AS build
WORKDIR /app
COPY pom.xml .
# Download dependencies first for better caching
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# Runtime stage
FROM tomcat:9-jdk11-openjdk-slim
LABEL maintainer="DevOps Workshop <workshop@example.com>"

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built application from the build stage
COPY --from=build /app/target/devops-demo.war /usr/local/tomcat/webapps/ROOT.war

# Set environment variables
ENV CATALINA_OPTS="-Xms512m -Xmx1024m"

# Expose the default Tomcat port
EXPOSE 8080

# Run Tomcat
CMD ["catalina.sh", "run"]
