#!/bin/bash

function ReleaseCandidate() {
  echo "Current version : $GIT_TAG"

  PATCH_VERSION="$V_MAJOR.$V_MINOR.$((V_PATCH + 1))-rc.0"
  MINOR_VERSION="$V_MAJOR.$((V_MINOR + 1)).0-rc.0"
  MAJOR_VERSION="$((V_MAJOR + 1)).0.0-rc.0"
  echo "Enter \"patch\" version to [$PATCH_VERSION]:"
  echo "Enter \"minor\" version to [$MINOR_VERSION]:"
  echo "Enter \"major\" version to [$MAJOR_VERSION]:"
  read -p "Select path or minor or major:" INPUT_STRING

  case $INPUT_STRING in
  "patch")
    V_PATCH=$((V_PATCH + 1))
    ;;
  "minor")
    V_MINOR=$((V_MINOR + 1))
    V_PATCH=0
    ;;
  "major")
    V_MAJOR=$((V_MAJOR + 1))
    V_MINOR=0
    V_PATCH=0
    ;;
  *)
    echo "Invalid input"
    echo "Select \"major\",\"minor\",\"patch\""
    exit
    ;;

  esac
  new_tag_version="$V_MAJOR.$V_MINOR.$V_PATCH-rc.0"

  confirm "Bump version number from $GIT_TAG to $new_tag_version?"

  echo "Will set new version to be $new_tag_version"
  git commit -m "Version bump to $new_tag_version"
  git tag -a -m "Tagging version $new_tag_version" "v$new_tag_version"
  git push origin --tags
  exit
}

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

else
  read -p "Release Candidate:" INPUT_STRING

  case "$INPUT_STRING" in
  [Nn][Oo] | [Nn])
    echo "Aborting."
    exit
    ;;
  [Yy][Ee][Ss] | [Yy][Ee] | [Yy])
    ReleaseCandidate
    ;;
  esac

  ReleaseCandidate

fi
