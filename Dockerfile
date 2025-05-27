FROM tomcat:9.0-jdk17

# Clean and prep
RUN rm -rf /usr/local/tomcat/webapps/* && \
    mkdir -p /usr/local/tomcat/webapps/ROOT

# Copy and extract WAR in the same step to avoid layer cache mismatch
COPY target/java-webapp.war /usr/local/tomcat/webapps/
RUN cd /usr/local/tomcat/webapps/ROOT && \
    jar -xf ../java-webapp.war

EXPOSE 8080
