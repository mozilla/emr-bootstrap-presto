#!/bin/bash

set -exo pipefail

# re-exec with sudo
if [ $(whoami) != root ]; then
  exec sudo "$0" "$@"
fi

# install tools
yum -y install jq tmux htop
