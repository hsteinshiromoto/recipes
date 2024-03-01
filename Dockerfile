# ---
# Build arguments
# ---
ARG DOCKER_PARENT_IMAGE
FROM $DOCKER_PARENT_IMAGE

# NB: Arguments should come after FROM otherwise they're deleted
ARG BUILD_DATE

# Silence debconf
ARG DEBIAN_FRONTEND=noninteractive

# Add vscode user to the container
ARG PROJECT_NAME
ARG PYTHON_VERSION
# ---
# Enviroment variables
# ---
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
ENV TZ Australia/Sydney
SHELL ["/bin/bash", "-c"]
ENV SHELL=/bin/bash
ENV PROJECT_NAME=$PROJECT_NAME
ENV HOME=/home/$PROJECT_NAME
ENV PYTHON_VERSION=$PYTHON_VERSION
ENV PYTHONPATH=$HOME

# Set container time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

LABEL org.label-schema.build-date=$BUILD_DATE \
    maintainer="hsteinshiromoto@gmail.com"

# Create the "home" folder
RUN mkdir -p $HOME
COPY . $HOME
WORKDIR $HOME

# ---
# Install pyenv
#
# References:
#   [1] https://stackoverflow.com/questions/65768775/how-do-i-integrate-pyenv-poetry-and-docker
# ---
# Install pyenv dependencies
RUN apt-get update && \
    apt-get install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git && \
    apt-get clean

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git $HOME/.pyenv
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"

# ---
# Install Python and set the correct version
# ---
RUN pyenv install $PYTHON_VERSION && pyenv global $PYTHON_VERSION

# ---
# Install NodeJS
# ---

RUN curl -fsSL https://deb.nodesource.com/setup_21.x | bash -
RUN apt-get update && \
    apt-get install -y nodejs

# ---
# Uncomment this Section to Install Additional Debian Packages
# ---

# COPY debian-requirements.txt /usr/local/debian-requirements.txt

# RUN apt-get update && \
#     DEBIAN_PACKAGES=$(egrep -v "^\s*(#|$)" /usr/local/debian-requirements.txt) && \
#     apt-get install -y $DEBIAN_PACKAGES && \
#     apt-get clean

# ---
# Copy Container Setup Scripts
# ---
# COPY pyproject.toml /usr/local/pyproject.toml
# COPY poetry.lock /usr/local/poetry.lock # Uncomment this line to include poetry.lock

# Get poetry
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="${PATH}:$HOME/.poetry/bin"
ENV PATH="${PATH}:$HOME/.local/bin"

RUN poetry config virtualenvs.create false
    # && cd /usr/local \
    # && poetry install --no-interaction --no-ansi

ENV PATH="${PATH}:$HOME/.local/bin"

# Need for Pytest
ENV PATH="${PATH}:${PYENV_ROOT}/versions/$PYTHON_VERSION/bin"

# ---
# Install Quartz
# ---
RUN cd $HOME \
    && git clone https://github.com/jackyzha0/quartz.git \
    && cd quartz \
    && npm i
    # && npx quartz create
