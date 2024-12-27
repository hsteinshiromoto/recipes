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
        usermod -u "$UID" "$USER" 2>/dev/null && {
                groupmod -g "$GID" "$USER" 2>/dev/null ||
                usermod -a -G "$GID" "$USER"
        }
        set -- gosu "${UID}:${GID}" "${@}"
fi

chown -R $USER /home/$USER

exec "$@"
