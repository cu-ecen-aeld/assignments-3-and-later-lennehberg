#!/bin/sh
# create a new file with name and path writefile with content writestr,
# overwriting any existing file and creating the path if
#  it doesn't exist.

# arg 1 - full path to a file (writefile)
# arg 2 - text string which will be written to file (writestr)

# error handling:
# missing arguments
# file could not be created

if [ $# -ne 2 ]; then
  echo "Missing arguments"
  exit 1
else
  if [ -z $1 ] || [ -z $2 ]; then
    echo "Empty file path or write string"
    exit 1
  else
    DIR=$(dirname "$1")
    if [ ! -d "$DIR" ]; then
      mkdir -p "$DIR" || {
        echo "Could not create directory"
        exit 1
      }
    fi
    touch $1
    if [ ! -e $1 ]; then
      echo "unable to open file"
      exit 1
    else
      echo $2 >$1
    fi
  fi
fi
