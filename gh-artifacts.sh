#!/usr/bin/env bash
source .env
set -a # test curl commands with $HEADERS again, since this may fix the vars

# from .env file:
# GH_USER=""
# GH_TOKEN=""
# BRANCH=""
# BASE_URL=https://api.github.com
# OWNER=""
# REPO=""
# WORKFLOW_NAME=""

# requires curl, jq, unzip, 

HEADERS='"Accept: application/json" -H "Authorization: Bearer $GH_TOKEN"'

# find latest workflow_run_id from workflow_name
WORKFLOW_RUN_ID=$(curl -sH $HEADERS \
  $BASE_URL/repos/$OWNER/$REPO/actions/runs?branch=$BRANCH |
  jq -r ".workflow_runs[] | select(.name == \"$WORKFLOW_NAME\") | .id" |
  awk 'NR==1 {print; exit}')
# `awk` is used to get the first line of the output, which should be the id of the latest run... I hope :)

function check() {
  # check if GH_TOKEN is set and if not, exit.
  if [ -z "$GH_TOKEN" ]; then
    echo "GH_TOKEN is not set"
    echo "Please set GH_TOKEN by running 'export GH_TOKEN=<token>'"
    exit 1
  fi

  # check if WORKFLOW_RUN_ID is set and if not, exit.
  if [ -z "$WORKFLOW_RUN_ID" ]; then
    echo "Could not find workflow run id for $WORKFLOW_NAME"
    exit 1
  else
    echo "Found workflow run id for $WORKFLOW_NAME on branch $BRANCH: https://github.com/$OWNER/$REPO/actions/runs/$WORKFLOW_RUN_ID"
  fi
}

# get artifact json data from the workflow run and store it in a variable
function getArtifactData() {
  artifact_info=$(curl -sH $HEADERS $BASE_URL/repos/$OWNER/$REPO/actions/runs/$WORKFLOW_RUN_ID/artifacts)
}

function getCommitSha() {
  curl -sH $HEADERS $BASE_URL/repos/$OWNER/$REPO/commits?sha=$BRANCH |
    jq -r '.[0].sha'
}

function getCommitMessage() {
  curl -sH $HEADERS $BASE_URL/repos/$OWNER/$REPO/commits/$(getCommitSha) |
    jq -r '.commit.message'
}

function getCommitAuthor() {
  curl -sH $HEADERS $BASE_URL/repos/$OWNER/$REPO/commits/$(getCommitSha) |
    jq -r '.commit.author.name'
}

function getCommitDate() {
  curl -sH $HEADERS $BASE_URL/repos/$OWNER/$REPO/commits/$(getCommitSha) |
    jq -r '.commit.author.date'
}

# get artifact_ids from workflow_run_id
# used by the downloadArtifact function
function getArtifactIds() {
  echo $artifact_info |
    jq -r .artifacts[].id
}

# get artifact_names from artifact_ids
function getArtifactNameIdPair() {
  echo $artifact_info |
    jq -r .artifacts[].name,.artifacts[].id
}

function createArray() {
  local json_data=$1
  local line_count=$(echo $json_data | jq -r '.artifacts[].id,.artifacts[].name' | wc -l)
  local line_count_half=$((line_count/2))

  local i=0
  array=()
  while [ $i -lt $line_count_half ]; do
    array[$i]+="$(echo $json_data | jq -r .artifacts[$i].id) $(echo $json_data | jq -r .artifacts[$i].name)"
    i=$((i+1))
  done
  declare -p array
}

# download artifacts using their artifact_id
function downloadArtifacts() {
  echo "Downloading artifacts..."
  echo ""
  mkdir -p artifacts && cd "$_"
  for artifact in $(getArtifactIds); do
    echo "Downloading $artifact" from $BASE_URL/repos/$OWNER/$REPO/actions/artifacts/$artifact/zip
    curl -u $GH_USER:$GH_TOKEN --output $artifact.zip -s --location-trusted $BASE_URL/repos/$OWNER/$REPO/actions/artifacts/$artifact/zip
  done
  cd ../
  echo "Finished downloading artifacts."
  echo ""
}

function listWorkflows() {
  printf '%s\n' "$(curl -s -u $GH_USER:$GH_TOKEN $BASE_URL/repos/$OWNER/$REPO/actions/workflows |
    jq -r .workflows[].name)"
}

# unzip artifacts from artifacts/
function unzipArtifacts() {
  echo "Unzipping artifacts..."
  mkdir -p artifacts && cd "$_"
  for file in $(ls ./); do
    echo "Unzipping $file"
    unzip -o $file -d $file-output 2>/dev/null
  done
  for file in $(ls ./); do
    echo "Unzipping $file"
    unzip -o $(echo $file)$(echo /*.zip) -d $(echo $file) 2>/dev/null
  done
  echo "Cleaning up..."
  echo $(rm [0-9]* 2>/dev/null)
  cd ../
  echo "Finished unzipping artifacts."
}

# name extracted artifact folders by their artifact_name
function nameArtifacts() {
  echo "Naming artifacts..."
  createArray "$(echo $artifact_info)"
  printf '%s\n' "${array[@]}"
  cd artifacts
  local ids=($(printf '%s\n' "${array[@]}" | awk '{print $1}')) # get just the id from a space-separated string
  local names=($(printf '%s\n' "${array[@]}" | awk '{print $2}')) # get just the name from a space-separated string
  local i=0

  while [ $i -lt ${#ids[@]} ]; do
    echo "Renaming ${ids[$i]}.zip-output to ${names[$i]}.zip"
    mv ${ids[$i]}.zip-output ${names[$i]}.zip
    i=$((i+1))
  done

  # for any folder ending in .zip, remove the .zip extension
  for file in $(ls ./); do
    if [[ $file == *.zip ]]; then
      echo "Renaming $file to $(echo $file | sed 's/\.zip//g')"
      mv $file $(echo $file | sed 's/\.zip//g')
    fi
  done

  cd ../
  echo "Finished naming artifacts."
}

function makeExecutable() {
  echo "Making artifacts executable..."
  chmod -R +x artifacts
}

function listCommands() {
  cat <<EOT
Usage:

  list-commands
    Lists all commands.

  download
    Downloads and extracts all artifacts from the latest workflow run.

  list-workflows
    Lists available workflows.

  help
    Shows this message.
    
For more information on the changes that triggered the build, go to:
https://github.com/$OWNER/$REPO/commit/$(getCommitSha)

To verify the desired artifacts were downloaded, go to:
https://github.com/$OWNER/$REPO/actions/runs/$WORKFLOW_RUN_ID
EOT
}

case $1 in
"download")
  check
  getArtifactData
  downloadArtifacts
  unzipArtifacts
  nameArtifacts
  makeExecutable
  ;;
"list-workflows")
  listWorkflows
  ;;
"name-artifacts")
  nameArtifacts
  ;;
"unzip")
  unzipArtifacts
  ;;
"help")
  listCommands
  ;;
*)
  echo "No command found."
  echo
  listCommands
  ;;
esac
