#!/usr/bin/env zsh

# 1. Copies first file from SOURCE_ROOT_DIR to DESTINATION_ROOT_DIR inside running Obsidian container
# 2. Generates Obsidian snippet to embed this file into notes.

# Configuration:
# Add volume mount to Obsidian container configuration
# choose any host path and mount to $SOURCE_ROOT_DIR inside container
# - ./obsidian/to-obsidian:/media/to-config-data

# root path of source directory **inside the container**
# Where to copy files from? Anything present in this dir will be copied to $DESTINATION_ROOT_DIR respecting relative paths
SOURCE_ROOT_DIR=/media/to-config-data
# root path of destination directory **inside the container**
# Where to copy files to? Poin to root path of your vault (otherwise Obsidian snippet generator will spit out incorrect path)
DESTINATION_ROOT_DIR=/config/data/obsidian/main

# Examples of where file will be copied using environment:
# SOURCE_ROOT_DIR=/media/to-config-data
# DESTINATION_ROOT_DIR=/config/data/obsidian/main
# Where file fill be copied? source file => destination file
# /media/to-config-data/a.txt => /config/data/obsidian/main/a.txt (root directory of main vault)
# /media/to-config-data/subdir/b.txt => /config/data/obsidian/main/subdir/b.txt (subdir of main vault)

# the container name to execute this script against
TARGET_CONTANER_NAME=obsidian
TARGET_CONTAINER_LABEL=one.dify.obsidian.putscript

# set owner user & group for copied file
# $PUID & $PGID from environment within running container (thats why \$PUID, $PUID would interpolate to environment from host)
FILE_USER=\$PUID
FILE_GROUP=\$PGID

# Script steps:
# 0. finds running obsidian container by its name or label
# 1. copies last modified regular file from anywhere in $SOURCE_ROOT_DIR to $DESTINATION_ROOT_DIR (preserving its path)
# 2. checks for copied file in destination and remove source if copy was successful
# 3. generates Obsidian embed code snippet for that file e.g. ![[image-name.png]]
# 4. copies Obsidian snippet to clipboard (to be pasted immedately to the note)

# Q: Why not use docker cp? A: In case that file with the same name already exists, docker cp will always override this file!

# Configuration check & cleanup
# Remove trailing slash if present
SOURCE_ROOT_DIR=${SOURCE_ROOT_DIR%/}
DESTINATION_ROOT_DIR=${DESTINATION_ROOT_DIR%/}
if [ -z "$SOURCE_ROOT_DIR" ]; then
  >&2 echo "SOURCE_ROOT_DIR variable must be set and cannot be /"
  exit 1
fi
if [ -z "$DESTINATION_ROOT_DIR" ]; then
  >&2 echo "DESTINATION_ROOT_DIR variable must be set and cannot be /"
  exit 1
fi

# example usage: find_obsidian_container mycontainer mylabel
find_obsidian_container() {
  # print $# $*
  if [[ "2" != "$#" ]]; then
    >&2 echo "Not enough arguments for $0 function. Got: $*"
    >&2 echo "Usage: $0 <container name> <fallback label>"
    >$2 echo "Use empty string for any argument you don't want to search for. E.g. $0 "" \"mylabel\""
    >&2 echo "Label must include \"yes\" or \"true\" as a value to be considered!"
    echo ""
    exit 1
  fi

  local container_name_to_search_for=$1
  local container_label_to_search_for=$2

  # find by name
  if [ -n "$container_name_to_search_for" ]; then
    local container_id=$(docker container ls -q --filter "name=$container_name_to_search_for" --filter "status=running")
    if [ -n "$container_id" ]; then
      echo "$container_id"
      exit 0
    fi
  fi
  
  # fallback, find by fallback label
  if [ -n "$container_label_to_search_for" ]; then
    # try "yes"
    local yes_container_ids=$(docker container ls -q --filter "label=$container_label_to_search_for=yes" --filter "status=running")
    # try "true"
    local true_container_ids=$(docker container ls -q --filter "label=$container_label_to_search_for=true" --filter "status=running")
    local container_ids=$(echo "${yes_container_ids}\n${true_container_ids}" | grep -v '^$')  # also removes blank lines
    if [ -z "$container_ids" ]; then
      # no container found
      echo ""
      exit 0
    fi

    local container_ids_count=$(echo "$container_ids" | wc -l)
    container_ids_count="${container_ids_count##*( )}"  # Remove leading spaces
    container_ids_count="${container_ids_count%%*( )}"  # Remove trailing spaces
    if [ "1" = "$container_ids_count" ]; then
      echo "$container_ids"
      exit 0
    else
      >&2 echo "Multiple obsidian containers found! Container ids: $(echo $container_ids | tr '\n' ' ')"
      echo ""
      exit 2
    fi
  fi

  # container not found => return empty string
  echo ""
}

OBSIDIAN_CONTAINER=$(find_obsidian_container "$TARGET_CONTANER_NAME" "$TARGET_CONTAINER_LABEL")

# function existed with non zero code
if [ "0" != "$?" ]; then
  echo "Failed to find Obsidian container"
  exit 1
fi

# function did return empty string
if [ -z "$OBSIDIAN_CONTAINER" ]; then
  echo "No running Obsidian container found"
  exit 1
fi

# stack principle (last modified file will be copied first!)
# exclude .DS_Store files anywhere
FULL_SOURCE_FILE_PATH=$(docker exec $OBSIDIAN_CONTAINER bash -c "find $SOURCE_ROOT_DIR -type f ! -name '.DS_Store' ! -name '.gitignore' -exec ls -t {} + | head -n 1")

if [ -z "$FULL_SOURCE_FILE_PATH" ]; then
  echo "No files to copy from $SOURCE_ROOT_DIR"
  exit 1
fi

PATH_TO_COPY=${FULL_SOURCE_FILE_PATH#$SOURCE_ROOT_DIR/} # remove base path from $FULL_SOURCE_FILE_PATH
TARGET_FILE_PATH="$DESTINATION_ROOT_DIR/$PATH_TO_COPY"

# copy file, but don't override if same file already exists
# also set owner user & group
COPY_EXIT_CODE=$(docker exec $OBSIDIAN_CONTAINER bash -c "if [ ! -f \"$TARGET_FILE_PATH\" ]; then cp -n \"$FULL_SOURCE_FILE_PATH\" \"$TARGET_FILE_PATH\"; chown $FILE_USER:$FILE_GROUP \"$TARGET_FILE_PATH\"; else exit 1; fi"; echo $?)

if [ "$COPY_EXIT_CODE" = "0" ]; then
  echo "File copied to \"$TARGET_FILE_PATH\""
else
  >&2 echo "TLDR: Failed to copy, perhaps file already exists \"$PATH_TO_COPY\""
  >&2 echo "Copy from \"$FULL_SOURCE_FILE_PATH\" to \"$TARGET_FILE_PATH\" failed!"
  exit 2
fi

FILE_EXIST_EXIT_CODE=$(docker exec $OBSIDIAN_CONTAINER bash -c "test -f \"$TARGET_FILE_PATH\""; echo $?)
if [ "$FILE_EXIST_EXIT_CODE" != "0" ]; then
  >&2 echo "File not present in destination \"$TARGET_FILE_PATH\", aborting!"
  exit 3
else
  echo "Will remove $FULL_SOURCE_FILE_PATH"
  REMOVED_EXIT_CODE=$(docker exec $OBSIDIAN_CONTAINER bash -c "rm \"$FULL_SOURCE_FILE_PATH\""; echo $?)
  if [ "$REMOVED_EXIT_CODE" != "0" ]; then
    >&2 echo "WARNING: File could not be removed from source location \"$FULL_SOURCE_FILE_PATH\"!"
  fi
fi

OBSIDIAN_EMBED_SNIPPET="![[$PATH_TO_COPY]]"
# copy to clipboard
echo "$OBSIDIAN_EMBED_SNIPPET" | pbcopy

echo "Generated Obsidian Markdown (its already in your clipboard):"
echo "===========================\n"
echo "$OBSIDIAN_EMBED_SNIPPET\n"
echo "==========================="
