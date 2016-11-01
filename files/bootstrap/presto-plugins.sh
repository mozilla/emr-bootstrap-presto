#!/bin/bash

set -exo pipefail

# re-exec with sudo into background
if [ $(whoami) != root ]; then
  sudo "$0" "$@" &
  exit 0
fi

# set variables
s3uri=$1

# wait until presto is installed and running
until test -s /var/run/presto/presto-server.pid; do sleep 1; done

# download presto plugins
aws s3 sync $s3uri /usr/lib/presto/plugin

# make sure all plugins are owned by presto user
chown -R presto:presto /usr/lib/presto/plugin

# restart presto
stop  presto-server
start presto-server
