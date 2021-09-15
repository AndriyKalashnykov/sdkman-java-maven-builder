.DEFAULT_GOAL := help

SHELL  				:= /bin/bash
SDKMAN				:= $(HOME)/.sdkman/bin/sdkman-init.sh
CURRENT_USER_NAME	:= $(shell whoami)

JAVA_VERSION 		:= 	11.0.11.hs-adpt
MAVEN_VERSION		:= 	3.8.1
USER_UID			:=	1000
USER_GID			:=	1000
USER_NAME			:=	user

IMAGE_NAME				:= $$DOCKER_LOGIN/sdkman:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION}
IMAGE_INLINE_CACHE_NAME	:= $$DOCKER_LOGIN/sdkman-cache:mvn-${MAVEN_VERSION}-jdk-${JAVA_VERSION}

SAMPLE_IMAGE_NAME	:= 	$$DOCKER_LOGIN/bitnami-tomcat9-jdk18-root-war:latest
SAMPLE_IMAGE_FILE	?= `pwd`/sample/Dockerifle

DOCKER_REGISTRY     :=  docker.io
export DOCKER_SCAN_SUGGEST=false

# make sure docker is installed
DOCKER_EXISTS	:= @printf "docker"
DOCKER_WHICH	:= $(shell which docker)
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
	@clear
	@echo "Usage: make COMMAND"
	@echo
	@echo "Commands :"
	@echo
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-18s\033[0m - %s\n", $$1, $$2}'

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

#build-inline-cache: @ Build remote cache for the SDKMAN! Java/Maven builder image 
build-inline-cache: check-env
	@DOCKER_BUILDKIT=1 docker build --build-arg BUILDKIT_INLINE_CACHE=1 --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $(IMAGE_INLINE_CACHE_NAME) .
	@DOCKER_BUILDKIT=1 docker push $(IMAGE_INLINE_CACHE_NAME)

#build: @ Build SDKMAN! Java/Maven builder image 
build: check-env
	@DOCKER_BUILDKIT=1 docker build --cache-from $(IMAGE_INLINE_CACHE_NAME) --build-arg JAVA_VERSION=${JAVA_VERSION} --build-arg MAVEN_VERSION=${MAVEN_VERSION} --build-arg USER_UID=${USER_UID} --build-arg USER_GID=${USER_GID} --build-arg USER_NAME=${USER_NAME} -t $(IMAGE_NAME) .

#verison: @ Run 'maven version' on SDKMAN! Java/Maven builder image
version: check-env build
	@docker run  --rm -u $$UID $(IMAGE_NAME) mvn -version

#it: @ Run SDKMAN! Java/Maven builder image interactively
it: check-env
	@docker run -it --rm -u $$UID $(IMAGE_NAME) bash

#push: @ Push builder image to a registry
push: login build
	@docker push $(IMAGE_NAME)

IMAGE_CMD := docker images --filter=reference=$(IMAGE_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_ID  := $(shell $(IMAGE_CMD))
IMAGE_CNT := $(shell $(IMAGE_CMD) | wc -l)

IMAGE_CACHE_CMD := docker images --filter=reference=$(IMAGE_INLINE_CACHE_NAME) --format "{{.ID}}" | awk '{print $$1}'
IMAGE_CACHE_ID  := $(shell $(IMAGE_CACHE_CMD))
IMAGE_CACHE_CNT := $(shell $(IMAGE_CACHE_CMD) | wc -l)

#delete: @ Delete builder image locally
delete: check-env

ifeq ($(shell test $(IMAGE_CNT) -gt 0; echo $$?),0)
# remove image
	docker rmi -f $(IMAGE_ID) 
endif

ifeq ($(shell test $(IMAGE_CACHE_CNT) -gt 0; echo $$?),0)
# remove image inline cache
	docker rmi -f $(IMAGE_CACHE_ID) 
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

#build-sample: @ Build sample image
build-sample: check-env
	@DOCKER_BUILDKIT=1 docker build -t $(SAMPLE_IMAGE_NAME) ./sample

#start-sample: @ Start sample image
start-sample: login
	@docker run --name t9 -d --rm -p 8080:8080 -p 8443:8443 $(SAMPLE_IMAGE_NAME)

#test-sample: @ Test sample image
test-sample: login

	@docker exec -t t9 sh -c "curl -k https://localhost:8443/index.html"

#stop-sample: @ Stop sample image
stop-sample: login
	@docker stop t9

SAMPLE_IMAGE_CMD := docker images --filter=reference=$(SAMPLE_IMAGE_NAME) --format "{{.ID}}" | awk '{print $$1}'
SAMPLE_IMAGE_ID  := $(shell $(SAMPLE_IMAGE_CMD))
SAMPLE_IMAGE_CNT := $(shell $(SAMPLE_IMAGE_CMD) | wc -l)

#delete-sample: @ Delete sample image locally
delete-sample: check-env

ifeq ($(shell test $(SAMPLE_IMAGE_CNT) -gt 0; echo $$?),0)
# remove sample image
	docker rmi -f $(SAMPLE_IMAGE_ID) 
endif	