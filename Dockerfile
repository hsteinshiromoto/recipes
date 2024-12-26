# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE=alpine:3.20.3
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE
ARG USER=user
# ---
# Enviroment variables
# ---
ENV GOSU_VERSION=1.17
ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8
ENV PATH="/nix/var/nix/profiles/default/bin:$PATH"
ENV DOCKER_USER=$USER
ENV HOME=/home/$USER
ENV WORKDIR=$HOME/workspace
ENV QUARTZ=$HOME/quartz
ENV TZ Australia/Sydney

LABEL org.label-schema.build-date=$BUILD_DATE \
	maintainer="hsteinshiromoto@gmail.com"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN mkdir -p $WORKDIR
RUN mkdir -p $QUARTZ

# ---
# Instal Alpine base packages
# ---
RUN apk --no-cache add \
	bash \
	curl \
	git \
	shadow \
	xz

# ---
# Install Nix Package Manager
# ---
COPY bin/get_nix.sh /usr/local
RUN chmod +x /usr/local/get_nix.sh && bash /usr/local/get_nix.sh

# ---
# Set user
# ---
RUN addgroup "$USER" \
	&& adduser -D "$USER" -G "$USER"


# ---
# Instal Dependencies
# ---
RUN nix-env -iA nixpkgs.zsh nixpkgs.nodejs_23

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
	&& sed "s/\$USER/$USER/g" -i /usr/local/bin/entrypoint.sh

# ---
# Copy dotfiles
# ---
USER $USER
RUN mkdir -p $HOME/dotfiles && \
	git clone https://github.com/hsteinshiromoto/dotfiles.linux.git $HOME/dotfiles

RUN cd $HOME/dotfiles && stow .

# ---
# Configure home folder
#
# This must be configured before installing packaged in the Docker image
# ---

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
