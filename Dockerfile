FROM ubuntu:18.04

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Docker Compose version
ARG COMPOSE_VERSION=1.24.0

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \ 
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    # Verify git, process tools installed
    && apt-get -y install git openssh-client less iproute2 procps \
    #
    # Install Docker CE CLI
    && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release \
    && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | (OUT=$(apt-key add - 2>&1) || echo $OUT) \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    #
    # Install Docker Compose
    && curl -sSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    #
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # install eqemu stuff
    && apt-get update \
    && apt-get -y install --no-install-recommends build-essential \
    cmake curl debconf-utils \
    git git-core \
    minizip make locales \
    nano open-vm-tools unzip uuid-dev iputils-ping wget \
    gdb valgrind \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN wget -c https://golang.org/dl/go1.12.17.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GO111MODULE="on"

RUN GOPATH=/home/vscode/go go get golang.org/x/tools/gopls@latest
RUN GOPATH=/home/vscode/go go get github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest
RUN GOPATH=/home/vscode/go go get github.com/mdempsky/gocode@latest
RUN GOPATH=/home/vscode/go go get github.com/ramya-rao-a/go-outline@latest
RUN GOPATH=/home/vscode/go go get github.com/rogpeppe/godef@latest
RUN GOPATH=/home/vscode/go go get golang.org/x/tools/cmd/goimports@latest
RUN GOPATH=/home/vscode/go go get golang.org/x/lint/golint@latest

# fix locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=en_US.UTF-8
ENV DEBIAN_FRONTEND=dialog
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8