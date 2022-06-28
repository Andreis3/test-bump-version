#!/bin/bash

GIT_TAG=$(git tag --sort=v:refname | tail -1 | grep -Po '(?<=v)[^"]*')
BASE_LIST=($(echo $GIT_TAG | tr '.' ' '))
V_MAJOR=${BASE_LIST[0]}
V_MINOR=${BASE_LIST[1]}
V_PATCH=${BASE_LIST[2]}
V_RC=${BASE_LIST[3]}

if [[ "$V_PATCH" == *"-rc"* ]]; then
  PATCH_LIST=($(echo $V_PATCH | tr '-' ' '))
  V_PATCH_BASE=${PATCH_LIST[0]}
  V_PATCH_RC=${PATCH_LIST[1]}
  echo "Current version : $GIT_TAG"
  PATCH_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH_BASE"
  echo "Enter \"patch\" version to [$PATCH_VERSION]:"

fi
