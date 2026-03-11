#!/bin/bash

# This script is meant to be run on the Raspberry Pi to set up the environment for the Polypod project. 
# Ideally, this should only be run once.

# Resolve the absolute path to this script's directory.
# Using $0 can yield "." or a relative path (especially when run as `./init.sh` or sourced),
# so prefer BASH_SOURCE.
SCRIPTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
INIT_SCRIPTS_DIR="$SCRIPTS_DIR/initializations"

# Iterate through all initialization scripts in the scripts directory and run them
# TODO: maybe this isn't the best approach. Splitting the `source` calls into their own lines instead of using a loop might be more 
# readable and easier to debug if something goes wrong. We could also add permanent env variables to indicate which scripts have already been run.
# For now though, this is more concise and scalable.
for i in "$INIT_SCRIPTS_DIR"/init_*.sh; do
    if [ -f "$i" ]; then
        echo "Running initialization script: $i"
        source "$i" # source the script to run it in the current shell
    else
        echo "No initialization scripts found in $INIT_SCRIPTS_DIR"
    fi
done

chmod +x "$SCRIPTS_DIR/startup.sh" # make the startup script executable

# Add autostart directory
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR" # create the autostart directory if it doesn't exist

# Copy the .desktop file to launch the startup script at boot
DESKTOP_FILE="$SCRIPTS_DIR/polypod_startup.desktop"

# check if desktop file DOESNT exist
if [ ! -f "$DESKTOP_FILE" ]; then
    echo "Error: Desktop file $DESKTOP_FILE does not exist. Please make sure it is in the scripts directory."
    exit 1
fi

# check if desktop file already exists in autostart directory
if [ -f "$AUTOSTART_DIR/polypod_startup.desktop" ]; then
    echo "Desktop file already exists in autostart directory. Skipping copy."
else
    cp "$DESKTOP_FILE" "$AUTOSTART_DIR/polypod_startup.desktop"
    echo "Copied desktop file to autostart directory: $AUTOSTART_DIR/polypod_startup.desktop"
fi

# copy the desktop file to the desktop for easy access
DESKTOP_DIR="$HOME/Desktop"
if [ -f "$DESKTOP_DIR/polypod_startup.desktop" ]; then
    echo "Desktop file already exists on desktop. Skipping copy."
else
    cp "$DESKTOP_FILE" "$DESKTOP_DIR/polypod_startup.desktop"
    echo "Copied desktop file to desktop: $DESKTOP_DIR/polypod_startup.desktop"
fi

echo "Initialization complete. Please reboot the Raspberry Pi to apply changes and start the Polypod application."