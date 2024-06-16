# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE
FROM --platform=linux/amd64 $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE

# Silence debconf
ARG DEBIAN_FRONTEND=noninteractive

# Add vscode user to the container
ARG PROJECT_NAME
# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
ENV TZ Australia/Sydney
ENV PROJECT_NAME=$PROJECT_NAME
ENV HOME=/home/$PROJECT_NAME
ENV PYTHON_VERSION=$PYTHON_VERSION
ENV PYTHONPATH=$HOME

LABEL org.label-schema.build-date=$BUILD_DATE \
    maintainer="hsteinshiromoto@gmail.com"

# ---
# Configure home folder
#
# This must be configured before installing packaged in the Docker image
# ---
RUN mkdir -p $HOME
WORKDIR $HOME

COPY bin/entrypoint.sh  /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
    

RUN apk add --update ansible npm bash zsh git neovim

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
# Install Quartz
# ---
RUN cd /usr/local \
    && git clone https://github.com/jackyzha0/quartz.git \
    && cd quartz \
    && npm i
    # && npx quartz create

RUN cd /usr/local/quartz && \
    git remote rm origin && \
    git remote add origin git@github.com:hsteinshiromoto/recipes.git

COPY .config/quartz/.github/workflows/deploy.yml /usr/local/quartz/.github/workflows/
COPY .config/quartz/quartz.config.ts /usr/local/quartz/

RUN mkdir -p $HOME/dotfiles && \
    git clone https://github.com/hsteinshiromoto/dotfiles.linux.git $HOME/dotfiles

ENV PATH="$HOME/.cargo/bin:${PATH}"

RUN ansible-playbook $HOME/dotfiles/packages.yml
RUN ansible-playbook $HOME/dotfiles/dotfiles.yml
  
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f","/dev/null"]
