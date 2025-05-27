FROM tomcat:9.0-jdk17

RUN mkdir -p /usr/local/tomcat/webapps/ROOT \
    /usr/local/tomcat/conf/Catalina/localhost && \
    chmod -R 777 /usr/local/tomcat/webapps \
    && chmod -R 777 /usr/local/tomcat/conf/Catalina && \
    rm -rf /usr/local/tomcat/webapps/*

# FIX: Merge COPY and extraction
COPY target/java-webapp.war /usr/local/tomcat/webapps/
RUN cd /usr/local/tomcat/webapps && \
    mkdir ROOT && \
    cd ROOT && \
    jar -xf ../java-webapp.war

EXPOSE 8080
