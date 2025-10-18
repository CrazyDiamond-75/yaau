#!/usr/bin/env bash

# Check the number of arguments, or if one is "--help", or "-h".
if [ "$#" -lt 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat << EOF
Usage: ./yaau.sh PATH
Reports if the repositories in the directory are outdated.
Updates all repositories and installs their packages.
Optional arguments:
    -h    --help      print this message.
    -v    --version   display yaau version.
    -f    --force     force installs all packages.
EOF
    exit
fi

# Check if version should be displayed.
if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
    cat << EOF
yauu --- Yet Another AUR Updater
Current version: v0.1
Copyright Henri Heyden, licenced under MIT.
EOF
    exit
fi

# Check if $1 is really a fitting path.
DIR="${!#}"
if [ ! -d $DIR ]; then
    printf "$DIR is not a path to a directory.\n"
    # Recursively call yauu.sh --help
    sh -c "$0 --help"
    exit
fi

# FORCE INSTALL PATH
if [ "$1" = "--force" ] || [ "$1" = "-f" ]; then
    printf "Warning: Installing all outdated packages.\n"
    printf "Confirm? [Y/n]\n"
    read PROMPT
    if [ ! "$PROMPT" = "Y" ] && [ ! "$PROMPT" = "" ]; then
        exit
    fi

    for SUB_DIR in $DIR/*; do
        # Check if SUB_DIR is really a directory of a repository.
        if [ ! -d $SUB_DIR/.git ]; then
            continue
        fi
        
        makepkg --needed -sirc -D $SUB_DIR
        printf "Installed package from $SUB_DIR.\n"
    done
    
    exit
fi

# DEFAULT BEHAVIOUR
printf "Checking all repos in $DIR for updates.\n"
UPDATE_COUNT=0
REPO_LIST=""

# Go through all indexes in the directory, and do the magic...
for SUB_DIR in $DIR/*; do
    # Check if SUB_DIR is really a directory of a repository.
    if [ ! -d $SUB_DIR/.git ]; then
        continue
    fi

    # Fetch the repos to refresh origin/master.
    # Redirect stdout to /dev/null.
    git -C $SUB_DIR fetch 1> /dev/null

    # Check if master and origin/master differ.
    OUTPUT=$(git -C $SUB_DIR status -sb)
    case $OUTPUT in
        *"behind"*)
            printf "Repository \"$SUB_DIR\" can be updated.\n"
            UPDATE_COUNT=$(($UPDATE_COUNT + 1))
            REPO_LIST="$REPO_LIST,$SUB_DIR"
    esac
done

if [ $UPDATE_COUNT -eq 0 ]; then
    printf "There are currently no possible updates.\n"
    exit
fi

printf "There are currently $UPDATE_COUNT possible updates.\n"
printf "Upgrade? [Y/n]\n"
read PROMPT
if [ ! "$PROMPT" = "Y" ] && [ ! "$PROMPT" = "" ]; then
    exit
fi

printf "Updating...\n"

# Remove the first element of the list, as it is empty.
REPO_LIST=$(printf "$REPO_LIST" | cut -c 2-)

# Setup for iterating though the list
OLD_IFS=$IFS
IFS=","
set -- $REPO_LIST # Sets $0, $1, etc to the relevant elements.
IFS=$OLD_IFS

# Go through all 
for SUB_DIR; do
    git -C $SUB_DIR pull 1> /dev/null
    makepkg -sirc -D $SUB_DIR
    printf "Updated package from $SUB_DIR\n".
done
