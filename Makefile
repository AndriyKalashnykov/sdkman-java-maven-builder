SHELL  				:= /bin/bash
SDKMAN				:= $(HOME)/.sdkman/bin/sdkman-init.sh
CURRENT_USER_NAME	:= $(shell whoami)

JAVA_VERSION 		:= 	11.0.11.hs-adpt
MAVEN_VERSION		:= 	3.8.1
USER_UID			:=	1000
USER_GID			:=	1000
USER_NAME			:=	user

check-env:
ifndef DOCKER_LOGIN
	$(error DOCKER_LOGIN is undefined)
endif

ifndef DOCKER_PWD
	$(error DOCKER_PWD is undefined)
endif

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
