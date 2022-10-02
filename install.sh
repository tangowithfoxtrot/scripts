#!/usr/bin/env bash

# This script "installs" the scripts in this repo by creating symlinks to them
#   in /usr/local/bin without the .sh extension.

for script in $(ls *.sh); do
  sudo ln -s $(pwd)/$script /usr/local/bin/$(echo $script | sed 's/\.sh//g')
done
