# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE
FROM --platform=linux/amd64 $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE
ARG DOCKER_USER=user
# Silence debconf
ARG DEBIAN_FRONTEND=noninteractive

# Add vscode user to the container
ARG PROJECT_NAME
# ---
# Enviroment variables
# ---
ENV DOCKER_USER=$DOCKER_USER
ENV HOME=/home/$DOCKER_USER
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
ENV TZ Australia/Sydney
ENV PROJECT_NAME=$PROJECT_NAME

LABEL org.label-schema.build-date=$BUILD_DATE \
    maintainer="hsteinshiromoto@gmail.com"

# ---
# Set user
# ---
RUN addgroup "$DOCKER_USER" \
    && adduser -D "$DOCKER_USER" -G "$DOCKER_USER"

    
# ---
# Instal Dependencies
# ---
RUN apk add --update bash cargo curl git neovim npm rust stow zsh

# ---
# Define Shell
# ---
SHELL ["/bin/bash", "-c"]
ENV SHELL=/bin/bash

# ---
# Install Gosy
#
# References:
#   [1] https://github.com/tianon/gosu/blob/master/INSTALL.md
# ---
ENV GOSU_VERSION 1.17
RUN set -eux; \
    \
    apk add --no-cache --virtual .gosu-deps \
        ca-certificates \
        dpkg \
        gnupg \
    ; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    \
# verify the signature
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    \
# clean up fetch dependencies
    apk del --no-network .gosu-deps; \
    \
    chmod +x /usr/local/bin/gosu; \
# verify that the binary works
    gosu --version; \
    gosu nobody true

# ---
# Copy necessary files for container to run
# ---
COPY bin/entrypoint.sh  /usr/local/bin/
RUN chmod 0755 /usr/local/bin/entrypoint.sh \
    && sed "s/\$DOCKER_USER/$DOCKER_USER/g" -i /usr/local/bin/entrypoint.sh
    
# ---
# Copy dotfiles
# ---
USER $DOCKER_USER
RUN mkdir -p $HOME/dotfiles && \
    git clone https://github.com/hsteinshiromoto/dotfiles.linux.git $HOME/dotfiles

RUN cd $HOME/dotfiles && stow .

# ---
# Configure home folder
#
# This must be configured before installing packaged in the Docker image
# ---
RUN cd $HOME && mkdir -p $PROJECT_NAME
RUN cd $HOME && mkdir -p .cache
WORKDIR $HOME

# ---
# Install Quartz
# ---
RUN cd $HOME \
    && git clone https://github.com/jackyzha0/quartz.git \
    && cd quartz \
    && npm i
    # && npx quartz create

RUN cd $HOME/quartz && \
    git remote rm origin && \
    git remote add origin git@github.com:hsteinshiromoto/recipes.git

COPY .config/quartz/.github/workflows/deploy.yml $HOME/quartz/.github/workflows/
COPY .config/quartz/quartz.config.ts $HOME/quartz/
COPY .config/nvim $HOME/.config/nvim

EXPOSE 8080

USER root 

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f","/dev/null"]
