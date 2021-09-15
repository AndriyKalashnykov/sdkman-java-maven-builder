FROM debian:stretch-slim

# Defining default Java and Maven version
ARG JAVA_VERSION="11.0.11.hs-adpt"
ARG MAVEN_VERSION="3.8.1"

# Defining default non-root user UID, GID, and name
ARG USER_UID="1000"
ARG USER_GID="1000"
ARG USER_NAME="user"

ENV TERM xterm
ENV TZ=America/New_York

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Creating default non-user
RUN groupadd -g $USER_GID $USER_NAME && useradd -m -g $USER_GID -u $USER_UID $USER_NAME

# Installing basic packages
RUN apt-get -y update && \
	apt-get install -y sudo ssh locales lsb-core nano zip unzip curl wget tree git gitg git-core \ 
    gnupg gnupg2 net-tools ca-certificates jq httpie htop nmon iputils-ping html-xml-utils libxml2-utils xmlstarlet libnss3-tools \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /tmp/* \
    && echo "\nexport TERM=$TERM" >> /home/$USER_NAME/.bashrc \
    && echo "\nalias ll='ls -l'" >> /home/$USER_NAME/.bashrc \
    && chown -R $USER_UID:$USER_GID  /home/$USER_NAME/ \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN curl -sSL "https://github.com/buildpacks/pack/releases/download/v0.20.0/pack-v0.20.0-linux.tgz" | tar -C /usr/local/bin/ --no-same-owner -xzv pack

# Switching to non-root user to install SDKMAN!
USER $USER_UID:$USER_GID
SHELL ["/bin/bash", "-c"]
WORKDIR /home/$USER_NAME

COPY ./scripts/ /home/$USER_NAME/scripts

# skip caching
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
# Downloading SDKMAN!
RUN curl -s "https://get.sdkman.io" | bash

# Installing Java and Maven, removing some unnecessary SDKMAN files
RUN bash -c "source $HOME/.sdkman/bin/sdkman-init.sh \
    && yes | sdk install java $JAVA_VERSION \
    && yes | sdk install maven $MAVEN_VERSION \
    && yes | sdk install gradle \
    && rm -rf $HOME/.sdkman/archives/* \
    && rm -rf $HOME/.sdkman/tmp/*" 

ENV GRADLE_HOME=/home/$USER_NAME/.sdkman/candidates/gradle/current
ENV MAVEN_HOME="/home/$USER_NAME/.sdkman/candidates/maven/current" 
ENV JAVA_HOME="/home/$USER_NAME/.sdkman/candidates/java/current" 
ENV PATH="$GRADLE_HOME/bin:$MAVEN_HOME/bin:$JAVA_HOME/bin:$PATH"

CMD ["/bin/bash"]
ENTRYPOINT bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && source $HOME/scripts/entry.sh && $0 $@"