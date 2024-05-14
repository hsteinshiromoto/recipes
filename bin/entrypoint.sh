#!/bin/bash

set -x
# get uid/gid
USER_UID=`ls -nd /home/recipes | cut -f3 -d' '`
USER_GID=`ls -nd /home/recipes | cut -f4 -d' '`

# get the current uid/gid of recipes
CUR_UID=`getent passwd recipes | cut -f3 -d: || true`
CUR_GID=`getent group recipes | cut -f3 -d: || true`

# if they don't match, adjust
if [ ! -z "$USER_GID" -a "$USER_GID" != "$CUR_GID" ]; then
    groupmod -g ${USER_GID} recipes
fi
if [ ! -z "$USER_UID" -a "$USER_UID" != "$CUR_UID" ]; then
    usermod -u ${USER_UID} recipes
    # fix other permissions
    find / -uid ${CUR_UID} -mount -exec chown ${USER_UID}.${USER_GID} {} \;
fi


# drop access to recipes and run cmd
exec gosu recipes "$@"

# ---
# References
#
# [1] https://stackoverflow.com/questions/45696676/set-docker-image-username-at-container-creation-time