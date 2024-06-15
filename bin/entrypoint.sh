#!/bin/bash
set -e

PROJECT_NAME=recipes 
# If "-e uid={custom/local user id}" flag is not set for "docker run" command, use 9999 as default
CURRENT_UID=${uid:-9999}
 
# Notify user about the UID selected
echo "Current UID : $CURRENT_UID"

# Create user called "docker" with selected UID
adduser -H -D -s /bin/bash -u $CURRENT_UID ${PROJECT_NAME}

# Set "HOME" ENV variable for user's home directory, uncomment in case it has not been set yet
# export HOME=/home/docker
 
# Execute process
exec gosu ${PROJECT_NAME} "$@"

# Note that, because gosu is installed via apt-get we only need to run using gosu

# ---
# References
#
# [1] https://stackoverflow.com/questions/45696676/set-docker-image-username-at-container-creation-time
