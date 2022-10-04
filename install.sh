#!/usr/bin/env bash

# this script "installs" the scripts in this repo by creating symlinks to them
#   in /usr/local/bin without the .sh extension.

# if the script is run with the --uninstall flag, it will remove the symlinks
#   from /usr/local/bin. Otherwise, it will create the symlinks.

# this script is idempotent. it will not create or remove symlinks if they
#   already exist or do not exist, respectively.

if [[ "$1" == "--uninstall" ]]; then
  echo "Removing symlinks from /usr/local/bin..."
  for script in $(ls *.sh); do
    script_name=${script%.sh}
    if [[ -L "/usr/local/bin/$script_name" ]]; then
      rm "/usr/local/bin/$script_name"
    fi
  done
  echo "Done."
else
  echo "Creating symlinks in /usr/local/bin..."
  for script in $(ls *.sh); do
    script_name=${script%.sh}
    if [[ ! -L "/usr/local/bin/$script_name" ]]; then
      ln -s "$PWD/$script" "/usr/local/bin/$script_name"
    fi
  done
  echo "Done."
fi