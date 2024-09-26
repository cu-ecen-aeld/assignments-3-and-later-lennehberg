#!/bin/sh
# FINDER
# print a message "The number of files are X and the
# number of matching lines is Y" where X is the number of files
# in the directory and all subdirectories and Y is the number
# of matching lines found in respective files, where a matching
# line refers to a lines whihc contains searchstr

# ARGUMENT:
# 1 - filesdir
# 2 - searchstr

# ERROR HANDLING:
# missing parameters
# filedir is not a valid files directory

# if the amount of varialbes is less than 2,
# echo an error message and exit 1
if [ $# -ne 2 ]; then
  echo "finder expected 2 arguments-r -e , $# were found"
  exit 1
fi

# DEBUG print
# echo "arg1: $1, arg2: $2"

SEARCH_DIR="$1"
SEARCH_STR="$2"

# if seracgh directory exists,
# look for files with searchstr, else
# echo an error message and exit 1
if [ -d $SEARCH_DIR ]; then
  APPEAR_COUNT=$(grep -r -e $SEARCH_STR $SEARCH_DIR | wc -l)
  FILE_COUNT=$(grep -r -e $SEARCH_STR -c $SEARCH_DIR | wc -l)
  echo "The number of files are $FILE_COUNT and the number of  matching lines are $APPEAR_COUNT"
else
  echo "$SEARCH_DIR not found!"
  exit 1
fi
