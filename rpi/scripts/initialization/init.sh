#!/bin/bash

# This script is meant to be run on the Raspberry Pi to set up the environment for the Polypod project. 
# Ideally, this should only be run once.

SCRIPTS_DIR=$(dirname "$0") # gets the current path to the scripts directory

# Iterate through all initialization scripts in the scripts directory and run them
# TODO: maybe this isn't the best approach. Splitting the `source` calls into their own lines instead of using a loop might be more 
# readable and easier to debug if something goes wrong. We could also add permanent env variables to indicate which scripts have already been run.
# For now though, this is more concise and scalable.
for i in "$SCRIPTS_DIR/init_"*.sh; do
    if [ -f "$i" ]; then
        echo "Running initialization script: $i"
        source "$i" # source the script to run it in the current shell
    else
        echo "No initialization scripts found in $SCRIPTS_DIR"
    fi
done
