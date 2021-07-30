SHELL  				:= /bin/bash
SDKMAN				:= $(HOME)/.sdkman/bin/sdkman-init.sh
CURRENT_USER_NAME	:= $(shell whoami)

JAVA_VERSION 		:= 	11.0.11.hs-adpt
MAVEN_VERSION		:= 	3.8.1
USER_UID			:=	1000
USER_GID			:=	1000
USER_NAME			:=	user

IMAGE_NAME 			:= 	$$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION}
SAMPLE_IMAGE_NAME	:= 	$$DOCKER_LOGIN/bitnami-tomcat9-jdk18-root-war:jdk-8.0.292.hs-adpt

export DOCKER_SCAN_SUGGEST=false

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
	@DOCKER_BUILDKIT=1 docker build --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $(IMAGE_NAME) .	

run: check-env 	login
	@docker run --rm -u $$UID $(IMAGE_NAME) mvn -version

it: check-env
	@docker run -it --rm -u $$UID $(IMAGE_NAME) bash


push: login build
	@docker push $(IMAGE_NAME)

CNT_IMAGE := $(shell docker images | grep $(IMAGE_NAME) | awk '{print $$3}' | wc -l)

delete: check-env

ifeq ($(shell test $(CNT_IMAGE) -gt 4; echo $$?),0)
# remove image
	@docker -q rmi $(IMAGE_NAME) 2>/dev/null
endif

CNT_TAG := $(shell docker images | grep '<none>' | awk '{print $$3}' | wc -l)
CNT_EXITED := $(shell docker ps -qa --no-trunc --filter 'status=exited' | wc -l)
CNT_NETWORK := $(shell docker network ls | grep 'bridge' | awk '/ / { print $$1 }' | wc -l)
CNT_DANGLING := $(shell docker volume ls -qf dangling=true | wc -l)

cleanup:

ifeq ($(shell test $(CNT_TAG) -gt 4; echo $$?),0)
# remove tagged <none> 	
	@docker rmi -f $$(docker images | grep '<none>' | awk '{print $$3}') 2>/dev/null
endif

ifeq ($(shell test $(CNT_EXITED) -gt 4; echo $$?),0)
# remove docker containers exited 
	@docker rm $$(docker ps -qa --no-trunc --filter 'status=exited')
endif	

ifeq ($(shell test $(CNT_NETWORK) -gt 4; echo $$?),0)
# remove networks
	@docker network rm $$(docker network ls | grep 'bridge' | awk '/ / { print $$1 }')
endif	

ifeq ($(shell test $(CNT_DANGLING) -gt 4; echo $$?),0)
# remove volumes
	@docker volume rm $$(docker volume ls -qf dangling=true)
endif

	@docker builder prune -af
#	$(call log_success, "Cleanup complete")

build-sample: check-env
	@DOCKER_BUILDKIT=1 docker build -t $(SAMPLE_IMAGE_NAME) ./sample

run-sample: login
	@docker run --name t9 -d --rm -p 8080:8080 -p 8443:8443 $(SAMPLE_IMAGE_NAME)

exec-sample: login

	@docker exec -t t9 sh -c "curl -k https://localhost:8443/index.html"

stop-sample: login
	@docker stop t9

CNT_SAMPLE_IMAGE := $(shell docker images | grep $(SAMPLE_IMAGE_NAME) | awk '{print $$3}' | wc -l)

delete-sample: check-env

ifeq ($(shell test $(CNT_SAMPLE_IMAGE) -gt 4; echo $$?),0)
# remove sample image
	@docker -q rmi $(SAMPLE_IMAGE_NAME) 2>/dev/null
endif	