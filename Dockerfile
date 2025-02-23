# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE=ubuntu:24.04
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE
ARG USER=user
ARG PROJECT_NAME

# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
	LC_ALL=C.UTF-8
ENV TZ=Australia/Sydney
ENV SHELL=/bin/bash
ENV PROJECT_NAME=$PROJECT_NAME
ENV HOME=/home/$USER
ENV WORKDIR=$HOME/$PROJECT_NAME

SHELL ["/bin/bash", "-c"]

# Set container time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
	maintainer="hsteinshiromoto@gmail.com"

# Create the "workdir" folder
RUN mkdir -p $WORKDIR

# ---
# Install Debian Dependencies
# ---

RUN apt -y update && apt install -y build-essential curl git sudo

# ---
# Install quartz
# ---
RUN apt-get update && \
	apt-get install -y ca-certificates gnupg && \
	mkdir -p /etc/apt/keyrings && \
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
	echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
	apt-get update && \
	apt-get install -y nodejs && \
	npm install -g npm@latest

RUN node -v
RUN npm --version

RUN cd $HOME && git clone https://github.com/jackyzha0/quartz.git && \
	cd quartz &&\
	npm i

EXPOSE 8080

ENTRYPOINT ["tail"]
CMD ["-f","/dev/null"]
