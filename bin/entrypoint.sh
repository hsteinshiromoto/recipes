#!/bin/sh
  
set -e
set -u

: "${UID:=0}"
: "${GID:=${UID}}"

if [ "$#" = 0 ]
then set -- "$(command -v bash 2>/dev/null || command -v sh)" -l
fi

if [ "$UID" != 0 ]
then
        usermod -u "$UID" "$DOCKER_USER" 2>/dev/null && {
                groupmod -g "$GID" "$DOCKER_USER" 2>/dev/null ||
                usermod -a -G "$GID" "$DOCKER_USER"
        }
        set -- gosu "${UID}:${GID}" "${@}"
fi

# chown -R $DOCKER_USER /home/$DOCKER_USER

exec "$@"
