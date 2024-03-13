#!/usr/bin/env bash
set -e

#relies on the local ~/.ssh being mouted to /.ssh into the docker container
#this script then sets up the key files

if [[ -d /.ssh ]]; then

  cp -R /.ssh /root/.ssh
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/*
  if compgen -G "/.ssh/*.pub" > /dev/null; then
    chmod 644 /root/.ssh/*.pub
  fi
  chmod 644 /root/.ssh/known_hosts

fi

#setup git safedirs
for dir in "/root/workdir/"; do
    if [ -d "$dir" ]; then
        git config --global --add safe.directory "$dir"
    fi
done


exec "$@"
