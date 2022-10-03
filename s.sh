#!/usr/bin/env bash

# this script allows us to use the encyption provided by
# `ansible-vault` to use with any utilities that accept secrets
# via environment variables.

# you need to replace dollar signs with underscores in the
# environment variable names. this is to avoid your shell
# from interpreting the dollar signs as variables before they
# are passed to this script.

set -e

# if no SECRETS_FILE is set in the environment, we assume that
# the secrets file is in the current directory:

if [ -z "$SECRETS_FILE" ]; then
  SECRETS_FILE=${SECRETS_FILE:-secrets.yml}
fi

if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo ""
  echo "  Usage: $0 <command> <arguments> <_variables> ..."
  echo "  Example: $0 your_command --any-arguments _VAR_1"
  echo ""
  echo "  Don't forget to set the SECRETS_FILE variable in this script"
  echo "    or set the SECRETS_FILE environment variable."
  echo ""
  exit 1
fi

# load secrets as environment variables with ansible-vault
# and export them as environment variables.
eval $(ansible-vault view $SECRETS_FILE | sed -e 's/:[^:\/\/]/=/g' -e 's/^/export /')

USER_COMMAND="$@"

for arg in $USER_COMMAND; do
  # replace the first underscore with a dollar sign
  arg=${arg/_/$}
  # append the argument to the virtual shell command
  VIRTUAL_SHELL_COMMAND="$VIRTUAL_SHELL_COMMAND $arg"
done

# execute the virtual shell command
eval $VIRTUAL_SHELL_COMMAND

# remove the environment variables
unset -v $(ansible-vault view $SECRETS_FILE | grep -v '^#' | sed -e 's/:.*//')
