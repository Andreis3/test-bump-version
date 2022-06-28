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

function confirm() {
    read -r -p "$@ [Y/n]: " confirm

    case "$confirm" in
    [Nn][Oo] | [Nn])
        echo "Aborting."
        exit
        ;;
    esac
}
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
GIT_TAG=$(git tag --sort=v:refname | tail -1 | grep -Po '(?<=v)[^"]*')
if [ "$GIT_TAG" == "" ]; then
    echo "Could not find a VERSION file"
    read -p "Do you want to create a version file and start from scratch? [y]" RESPONSE
    if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "y" ]; then

        GIT_TAG="0.0.1"
        git log --pretty=format:" - %s" >>CHANGES
        echo "" >>CHANGES
        echo "" >>CHANGES
        git commit -m "Added VERSION and CHANGES files, Version bump to v0.0.1"
        git tag -a -m "Tagging version 0..0" "v0.0.1"
        git push origin --tags
    fi
else
    BASE_LIST=($(echo $GIT_TAG | tr '.' ' '))
    V_MAJOR=${BASE_LIST[0]}
    V_MINOR=${BASE_LIST[1]}
    V_PATCH=${BASE_LIST[2]}
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
fi
