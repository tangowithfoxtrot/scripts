#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

VERSION="0.0.1"

# defaults
bold=""
underline=""
nounderline=""
black=""
red=""
green=""
yellow=""
blue=""
magenta=""
cyan=""
white=""
normal=""

if [[ -t 1 ]]; then
  ncolors=$(tput colors)
  if [[ -n "${ncolors}" ]] && [[ "${ncolors}" -ge 8 ]]; then
    bold="$(tput bold)"
    underline="$(tput smul)"
    nounderline="$(tput rmul)"
    black="$(tput setaf 0)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    blue="$(tput setaf 4)"
    magenta="$(tput setaf 5)"
    cyan="$(tput setaf 6)"
    white="$(tput setaf 7)"
    normal="$(tput sgr0)"
  fi
fi

help() {
  cat <<EOF
${bold}${green}Secrets Injector${white}${normal}

Inject secrets from Bitwarden into a command.

${underline}Usage:${nounderline}
  ${bold}${green}${0##*/}${white}${normal} [${magenta}OPTIONS${white}] <${cyan}COMMAND${white}>

  ${bold}${green}${0##*/}${white}${normal} '${cyan}npm run start${white}' ${blue}# Run \`npm run start\` with secrets injected.${white}
  ${bold}${green}${0##*/}${white}${normal} ${magenta}-i${white} '${cyan}docker-compose up${white}' ${blue}# Supply <BWS_ACCESS_TOKEN> interactively.${white}
  ${bold}${green}${0##*/}${white}${normal} '${cyan}echo \$KEYNAME_FROM_BITWARDEN${white}' ${blue}# Retrieve a secret from Bitwarden.${white}

${underline}Options:${nounderline}
  ${magenta}-i, --interactive${white}   Supply <${magenta}BWS_ACCESS_TOKEN${white}> interactively.
  ${magenta}-h, --help${white}          Show this help message and exit.
  ${magenta}-v, --version${white}       Show version information and exit.
EOF
}

bws_list() {
  if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    echo "BWS_ACCESS_TOKEN is not set."
    read -r -s -p "Paste your access token: " BWS_ACCESS_TOKEN
    echo
    export BWS_ACCESS_TOKEN
  fi

  secrets_json=$(bws secret list | jq '[.[] | {key: .key, value: .value}]')

  for row in $(echo "${secrets_json}" | jq -r '.[] | @base64'); do
    _jq() {
      echo "${row}" | base64 --decode | jq -r "${1}"
    }

    key=$(_jq '.key')
    value=$(_jq '.value')

    export "${key}"="${value}"
  done
}

main() {
  bws_list
  bash -c "${@}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  while [[ "${#}" -gt 0 ]]; do
    case "${1}" in
    -h | --help)
      help
      exit 0
      ;;
    -v | --version)
      echo "$VERSION"
      exit 0
      ;;
    -i | --interactive)
      read -r -s -p "Paste your access token: " BWS_ACCESS_TOKEN
      echo
      export BWS_ACCESS_TOKEN
      bws_list
      shift
      ;;
    *)
      break
      ;;
    esac
  done

  # if more than 0 arguments, run main
  if [[ "${#}" -gt 0 ]]; then
    main "${@}"
  elif [[ "${#}" -eq 0 ]]; then
    help
    exit 0
  fi
fi
