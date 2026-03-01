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
    if [ "$i" = "$INIT_SCRIPTS_DIR/init_waveshare35e.sh" ]; then
        echo "Skipping initialization script: $i (not needed for current hardware)"
        echo "NOTE: This is to be removed when I test with the actual hardware."
        continue
    fi

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
mkdir -p "$AUTOSTART_DIR" # ensure the autostart directory exists

# Copy .desktop file to autostart directory 
AUTOSTART_PATH="$AUTOSTART_DIR/polypod.desktop"
if [ -f "$AUTOSTART_PATH" ]; then
    echo "Autostart file already exists at $AUTOSTART_PATH. Skipping copy."
else
    cp "$SCRIPTS_DIR/polypod.desktop" "$AUTOSTART_PATH"
    echo "Copied polypod.desktop to $AUTOSTART_PATH for autostart on boot."
fi

# copy .desktop file to the desktop for easy access
DESKTOP_PATH="$HOME/Desktop/polypod.desktop"
if [ -f "$DESKTOP_PATH" ]; then
    echo "Desktop shortcut already exists at $DESKTOP_PATH. Skipping copy."
else
    cp "$SCRIPTS_DIR/polypod.desktop" "$DESKTOP_PATH"
    echo "Copied polypod.desktop to $DESKTOP_PATH for easy access."
fi

echo "Initialization complete. Please reboot the Raspberry Pi to apply changes and start the Polypod application."