ARG JAVA_VERSION="8.0.292.hs-adpt"
ARG MAVEN_VERSION="3.8.1"

FROM andriykalashnykov/sdkman:mvn-$MAVEN_VERSION-jdk-$JAVA_VERSION as build

WORKDIR $HOME/

RUN git clone https://github.com/AndriyKalashnykov/tomcat-root-war.git $HOME/tomcat-root-war

WORKDIR ${HOME}/tomcat-root-war/

RUN mvn dependency:go-offline -f $HOME/tomcat-root-war/pom.xml

RUN mvn package -f $HOME/tomcat-root-war/pom.xml

# Tomcat 9.0.34-0 and JDK 1.8
FROM docker.io/andriykalashnykov/bitnami-tomcat9-jdk18:1.0

ARG UID=1001
ARG USER="user"

LABEL Name="bitnami-tomcat9-jdk18-root-war" \
    Vendor="Andriy Kalashnykov" \
    Maintainer="Andriy Kalashnykov (https://github.com/AndriyKalashnykov/)" \
    Version="1.0" \
    License="Apache License, Version 2.0"

COPY --chown=$UID:$UID ./tomcat/conf /opt/bitnami/tomcat/conf

RUN rm -rf /opt/bitnami/tomcat/webapps/ROOT
RUN rm -rf /opt/bitnami/tomcat/webapps_default/ROOT

COPY --from=build --chown=$UID:$UID /home/$USER/tomcat-root-war/target/ROOT.war /opt/bitnami/tomcat/webapps

RUN cp -r /opt/bitnami/tomcat/webapps_default/manager/ /opt/bitnami/tomcat/webapps
RUN cp -r /opt/bitnami/tomcat/webapps_default/host-manager/ /opt/bitnami/tomcat/webapps

EXPOSE 8080
EXPOSE 8443