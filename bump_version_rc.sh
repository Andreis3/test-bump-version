#!/bin/bash

# works with a file called VERSION in the current directory,
# the contents of which should be a semantic version number
# such as "1.2.3"

# this script will display the current version, automatically
# suggest a "minor" version update, and ask for input to use
# the suggestion, or a newly entered value.

# once the new version number is determined, the script will
# pull a list of changes from git history, prepend this to
# a file called CHANGES (under the title of the new version
# number) and create a GIT tag.

GIT_STATUS=$(git status --porcelain)
if [ "$GIT_STATUS" != "" ]; then
  echo "Uncommitted changes exist in the working directory."
  echo "Aborting."
  exit
fi
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$GIT_BRANCH" != "master" ]; then
  echo "You are not on the master branch."
  echo "Aborting."
  exit
fi
GIT_DIFF=$(git diff @{upstream} --stat)
if [ "$GIT_DIFF" != "" ]; then
  echo "Differences exist between the master branch and the upstream branch."
  echo "Aborting."
  exit
fi

function confirm() {
  read -r -p "$@ [Y/n]: " confirm

  case "$confirm" in
  [Nn][Oo] | [Nn])
    echo "Aborting."
    exit
    ;;
  esac
}

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

function Production() {
  echo "Current version : $GIT_TAG"

  PATCH_VERSION="$V_MAJOR.$V_MINOR.$((V_PATCH + 1))"
  MINOR_VERSION="$V_MAJOR.$((V_MINOR + 1)).0"
  MAJOR_VERSION="$((V_MAJOR + 1)).0.0"
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
  new_tag_version="$V_MAJOR.$V_MINOR.$V_PATCH"
  confirm "Bump version number from $GIT_TAG to $new_tag_version?"
  echo "Will set new version to be $new_tag_version"
  git commit -m "Version bump to $new_tag_version"
  git tag -a -m "Tagging version $new_tag_version" "v$new_tag_version"
  git push origin --tags
  exit
}

function PreReleaseOrProduction() {
  echo "Current version : $GIT_TAG"
  BASE_LIST=($(echo $GIT_TAG | tr '.' ' '))
  V_MAJOR=${BASE_LIST[0]}
  V_MINOR=${BASE_LIST[1]}
  V_PATCH=${BASE_LIST[2]}
  V_PATCH_RC=${BASE_LIST[3]}

  PATCH_LIST=($(echo $V_PATCH | tr '-' ' '))
  V_PATCH_BASE=${PATCH_LIST[0]}

  PRE_RELEASE_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH.$((V_PATCH_RC + 1))"
  PRODUCTION_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH_BASE"
  echo "Enter \"pre-release\" version to [$PRE_RELEASE_VERSION]:"
  echo "Enter \"production\" version to [$PRODUCTION_VERSION]:"

  read -p "Select \"pre-release\" => [pre] \"production\" => [prod]:" INPUT_STRING

  case $INPUT_STRING in
  "pre")
    confirm "Bump version number from $GIT_TAG to $PRE_RELEASE_VERSION?"

    echo "Will set new version to be $PRE_RELEASE_VERSION"
    git commit -m "Version bump to $PRE_RELEASE_VERSION"
    git tag -a -m "Tagging version $PRE_RELEASE_VERSION" "v$PRE_RELEASE_VERSION"
    git push origin --tags
    ;;
  "prod")
    confirm "Bump version number from $GIT_TAG to $PRODUCTION_VERSION?"

    echo "Will set new version to be $PRODUCTION_VERSION"
    git commit -m "Version bump to $PRODUCTION_VERSION"
    git tag -a -m "Tagging version $PRODUCTION_VERSION" "v$PRODUCTION_VERSION"
    git push origin --tags
    ;;
  *)
    echo "Invalid input"
    echo "Select \"pre-release\" => [pre] \"production\" => [prod]"
    exit
    ;;
  esac
  exit
}

GIT_TAG=$(git tag --sort=taggerdate | tail -1 | grep -Po '(?<=v)[^"]*')
BASE_LIST=($(echo $GIT_TAG | tr '.' ' '))
V_MAJOR=${BASE_LIST[0]}
V_MINOR=${BASE_LIST[1]}
V_PATCH=${BASE_LIST[2]}
V_RC=${BASE_LIST[3]}

if [[ "$V_PATCH" == *"-rc"* ]]; then
  PATCH_LIST=($(echo $V_PATCH | tr '-' ' '))
  V_PATCH_BASE=${PATCH_LIST[0]}
  V_PATCH_RC=${PATCH_LIST[1]}

  PreReleaseOrProduction

else
  read -p "Create Release-Candidate => [RC/rc] or Production => [PROD/prod]:" INPUT_STRING

  case "$INPUT_STRING" in
  "PROD" | "prod")
    Production
    ;;
  "RC" | "rc")
    ReleaseCandidate
    ;;
  *)
    echo "Invalid input"
    echo "Select \"RC/rc\" or \"PROD/prod\""
    exit
    ;;
  esac

fi
