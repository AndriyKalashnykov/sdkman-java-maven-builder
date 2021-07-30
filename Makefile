.DEFAULT_GOAL := help

SHELL  				:= /bin/bash
SDKMAN				:= $(HOME)/.sdkman/bin/sdkman-init.sh
CURRENT_USER_NAME	:= $(shell whoami)

JAVA_VERSION 		:= 	11.0.11.hs-adpt
MAVEN_VERSION		:= 	3.8.1
USER_UID			:=	1000
USER_GID			:=	1000
USER_NAME			:=	user

IMAGE_NAME 			:= 	$$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION}
SAMPLE_IMAGE_NAME	:= 	$$DOCKER_LOGIN/bitnami-tomcat9-jdk18-root-war
SAMPLE_IMAGE_FILE   ?= `pwd`/sample/Dockerifle


DOCKER_REGISTRY     :=  docker.io
export DOCKER_SCAN_SUGGEST=false

# make sure docker is installed
DOCKER_EXISTS := @printf "docker"
DOCKER_WHICH := $(shell which docker)
ifeq ($(strip $(DOCKER_WHICH)),)
	DOCKER_EXISTS := @echo "ERROR: docker not found. See: https://docs.docker.com/get-docker/" && exit 1
endif

DOCKER_LOGIN_EXISTS := @printf "DOCKER_LOGIN"
ifndef DOCKER_LOGIN
#	$(error DOCKER_PWD is undefined)
	DOCKER_LOGIN_EXISTS := @echo "DOCKER_LOGIN is undefined" && exit 1
endif

DOCKER_PWD_EXISTS := @printf "DOCKER_PWD"
ifndef DOCKER_PWD
#	$(error DOCKER_PWD is undefined)
	DOCKER_PWD_EXISTS := @echo "DOCKER_PWD is undefined" && exit 1
endif

#help: @ List available tasks on this project
help:
	@echo "Available tasks:"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-14s\033[0m - %s\n", $$1, $$2}'

#check-env: @ Check environment variables and installed tools
check-env:

	@printf "\xE2\x9C\x94 "
	$(DOCKER_EXISTS)
	@printf " "
	$(DOCKER_LOGIN_EXISTS)
	@printf " "
	$(DOCKER_PWD_EXISTS)
	@echo ""	
#	$(debug   DOCKER_EXISTS is $(DOCKER_EXISTS))

#login: @ Login to a registry
login: check-env
	@docker login --username $$DOCKER_LOGIN --password $$DOCKER_PWD $$DOCKER_REGISTRY

#build: @ Build SDKMAN! Java/Maven builder image
build: check-env
	@DOCKER_BUILDKIT=1 docker build --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $(IMAGE_NAME) .	

#run: @ Run builder image
run: check-env 	login
	@docker run --rm -u $$UID $(IMAGE_NAME) mvn -version

#it: @ Run interactive builder image 
it: check-env
	@docker run -it --rm -u $$UID $(IMAGE_NAME) bash

#push: @ Push builder image to a registry
push: login build
	@docker push $(IMAGE_NAME)

CNT_IMAGE := $(shell docker images | grep $(IMAGE_NAME) | awk '{print $$3}' | wc -l)

#delete: @ Push builder image locally
delete: check-env

ifeq ($(shell test $(CNT_IMAGE) -gt 0; echo $$?),0)
# remove image
	@docker -q rmi $(IMAGE_NAME) 2>/dev/null
endif

CNT_TAG_CMD     := docker images | grep '<none>' | awk '{print $$3}'
CNT_TAG         := $(shell $(CNT_TAG_CMD) | wc -l)

CNT_EXITED_CMD  := docker ps -qa --no-trunc --filter 'status=exited'
CNT_EXITED      := $(shell $(CNT_EXITED_CMD) | wc -l)

CNT_NETWORK_CMD := docker network ls | awk '$$3 == "bridge" && $$2 != "bridge" { print $$1 }'
CNT_NETWORK     := $(shell $(CNT_NETWORK_CMD) | wc -l)

CNT_DANGLING_CMD := docker volume ls -qf dangling=true
CNT_DANGLING     := $(shell $(CNT_DANGLING_CMD) | wc -l)


#cleanup: @ Cleanup docker images, containers, volumes, networks, build cache
cleanup:

ifeq ($(shell test $(CNT_TAG) -gt 0; echo $$?),0)
# remove tagged <none> 	
	@docker rmi -f $$($(CNT_TAG_CMD))
endif

ifeq ($(shell test $(CNT_EXITED) -gt 0; echo $$?),0)
# remove docker containers exited 
	@docker rm $$($(CNT_EXITED_CMD))
endif	

ifeq ($(shell test $(CNT_NETWORK) -gt 0; echo $$?),0)
# remove networks
	@docker network rm -q $$($(CNT_NETWORK_CMD))
endif	

ifeq ($(shell test $(CNT_DANGLING) -gt 0; echo $$?),0)
# remove volumes
	@docker volume rm $$($(CNT_DANGLING_CMD))
endif

	@docker builder prune -af

build-sample: check-env
	@DOCKER_BUILDKIT=1 docker build -t $(SAMPLE_IMAGE_NAME) ./sample

run-sample: login
	@docker run --name t9 -d --rm -p 8080:8080 -p 8443:8443 $(SAMPLE_IMAGE_NAME)

exec-sample: login

	@docker exec -t t9 sh -c "curl -k https://localhost:8443/index.html"

stop-sample: login
	@docker stop t9s

SAMPLE_IMAGE_CMD := docker images | grep $(SAMPLE_IMAGE_NAME) | awk '{print $$3}'
SAMPLE_IMAGE_ID  := $(shell $(SAMPLE_IMAGE_CMD))
SAMPLE_IMAGE_CNT := $(shell $(SAMPLE_IMAGE_CMD) | wc -l)

delete-sample: check-env

ifeq ($(shell test $(SAMPLE_IMAGE_CNT) -gt 0; echo $$?),0)
# remove sample image
	docker rmi -f $(SAMPLE_IMAGE_ID) 
endif	