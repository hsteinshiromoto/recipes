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

# Install pyenv and gosu dependencies
RUN apt-get update && \
    apt-get install -y wget build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev sudo \
    git gosu && \
    apt-get clean

# ---
# Install gosu
#
# References:
#   [1] https://github.com/tianon/gosu/blob/master/INSTALL.md
#   [2] https://stackoverflow.com/questions/45696676/set-docker-image-username-at-container-creation-time
# ---

RUN rm -rf /var/lib/apt/lists/*; \
    gosu nobody true

# ---
# Configure home folder
# ---
RUN mkdir -p $HOME
WORKDIR $HOME

COPY bin/entrypoint.sh  /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---
# Install pyenv
#
# References:
#   [1] https://stackoverflow.com/questions/65768775/how-do-i-integrate-pyenv-poetry-and-docker
# ---
RUN git clone --depth=1 https://github.com/pyenv/pyenv.git $HOME/.pyenv
ENV PYENV_ROOT="${HOME}/.pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"

# ---
# Install Python and set the correct version
# ---
RUN pyenv install $PYTHON_VERSION && pyenv global $PYTHON_VERSION

# ---
# Copy Container Setup Scripts
# ---

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
RUN curl -s https://deb.nodesource.com/setup_22.x | sudo -E bash -
RUN apt-get update && \
    apt-get install -y nodejs

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

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["tail", "-f","/dev/null"]
