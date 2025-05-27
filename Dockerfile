FROM tomcat:9.0-jdk17

RUN mkdir -p /usr/local/tomcat/webapps/ROOT \
    /usr/local/tomcat/conf/Catalina/localhost && \
    chmod -R 777 /usr/local/tomcat/webapps \
    && chmod -R 777 /usr/local/tomcat/conf/Catalina

# Clean any default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR
COPY target/java-webapp.war /usr/local/tomcat/webapps/ROOT.war

# Explicitly extract it
RUN cd /usr/local/tomcat/webapps && \
    mkdir ROOT && \
    cd ROOT && \
    jar -xf ../ROOT.war

EXPOSE 8080
