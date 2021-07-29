FROM andriykalashnykov/sdkman:mvn-3.8.1-jdk-8.0.292.hs-adpt as build

ARG USER_NAME="user"

WORKDIR /home/$USER_NAME
RUN git clone https://github.com/AndriyKalashnykov/tomcat-root-war.git
WORKDIR /home/$USER_NAME/tomcat-root-war
RUN mvn dependency:go-offline 
RUN mvn package -f /home/$USER_NAME/tomcat-root-war/pom.xml

# Tomcat 9.0.34-0 and JDK 1.8.242-0
FROM docker.io/andriykalashnykov/bitnami-tomcat9-jdk18:1.0

ARG UID=1001
ARG USER_NAME="user"

LABEL Name="bitnami-tomcat9-jdk18-root-war" \
    Vendor="Andriy Kalashnykov" \
    Maintainer="Andriy Kalashnykov (https://github.com/AndriyKalashnykov/)" \
    Version="1.0" \
    License="Apache License, Version 2.0"

COPY --chown=$UID:$UID ./tomcat/conf /opt/bitnami/tomcat/conf

RUN rm -rf /opt/bitnami/tomcat/webapps/ROOT
RUN rm -rf /opt/bitnami/tomcat/webapps_default/ROOT

COPY --from=build --chown=$UID:$UID /home/$USER_NAME/tomcat-root-war/target/ROOT.war /opt/bitnami/tomcat/webapps

RUN cp -r /opt/bitnami/tomcat/webapps_default/manager/ /opt/bitnami/tomcat/webapps
RUN cp -r /opt/bitnami/tomcat/webapps_default/host-manager/ /opt/bitnami/tomcat/webapps

EXPOSE 8080
EXPOSE 8443