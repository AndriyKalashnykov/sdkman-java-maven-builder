SHELL  				:= /bin/bash
SDKMAN				:= $(HOME)/.sdkman/bin/sdkman-init.sh
CURRENT_USER_NAME	:= $(shell whoami)

JAVA_VERSION 		:= 	8.0.292.hs-adpt
# 11.0.11.hs-adpt
MAVEN_VERSION		:= 	3.8.1
USER_UID			:=	1000
USER_GID			:=	1000
USER_NAME			:=	user

# make sure docker is installed
DOCKER_EXISTS := @echo "Found docker"
DOCKER_WHICH := $(shell which docker)
ifeq ($(strip $(DOCKER_WHICH)),)
	DOCKER_EXISTS := @echo "ERROR: docker not found. See: https://docs.docker.com/get-docker/" && exit 1
endif

log_success = (echo "\x1B[32m>> $1\x1B[39m")
log_error = (>&2 echo "\x1B[31m>> $1\x1B[39m" && exit 1)

check-env:
ifndef DOCKER_LOGIN
	$(error DOCKER_LOGIN is undefined)
endif

ifndef DOCKER_PWD
	$(error DOCKER_PWD is undefined)
endif

	$(DOCKER_EXISTS)

login: check-env
	@docker login --username $$DOCKER_LOGIN --password $$DOCKER_PWD docker.io

build: check-env
	@DOCKER_BUILDKIT=1 docker build --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION} .	

run: check-env login
	@docker run --rm -u $$UID $$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION} mvn -version

it: check-env
	@docker run -it --rm -u $$UID $$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION} bash


push: login build
	@docker push $$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION}

delete: check-env
	@docker rmi $$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION}

build-sample: check-env
	@DOCKER_BUILDKIT=1 docker build  -t $$DOCKER_LOGIN/bitnami-tomcat9-jdk18-root-war:jdk-8.0.292.hs-adpt ./sample


run-sample: login
	@docker run --name t9 -d --rm -p 8080:8080 -p 8443:8443 $$DOCKER_LOGIN/bitnami-tomcat9-jdk18-root-war:jdk-8.0.292.hs-adpt

exec-sample: login

	@docker exec -t t9 sh -c "curl -k https://localhost:8443/index.html"


stop-sample: login
	@docker stop t9