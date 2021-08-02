# SDKMan! Java/Maven Builder docker image
Docker image with various Java and Maven versions to build Java Maven projects

## Pre-Requisites

* Docker

* DockerHub login and password
  
    ```bash
    DOCKER_LOGIN= 
    DOCKER_PWD=
    ```

### Build Docker Image with default JAVA_VERSION and MAVEN_VERSION

```bash
make build
```

### Build Docker Image with alternative JAVA_VERSION and MAVEN_VERSION and or different UID,GID,USER_NAME

```bash
make build JAVA_VERSION=16.0.1.hs-adpt MAVEN_VERSION=3.8.1 USER_UID=1000 USER_GID=1000 USER_NAME=user
```

### Run Docker Image Interactively

```bash
make it
```

### Run Docker Image Interactively

```bash
make it
```

### Run Maven version

```bash
make run
```
### Push Docker to DockerHub

```bash
make push
```

### Delete Docker Image

```bash
make delete
```