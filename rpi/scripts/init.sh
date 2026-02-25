#!/bin/bash

# This script is meant to be run on the Raspberry Pi to set up the environment for the Polypod project. 
# Ideally, this should only be run once.

SCRIPTS_DIR=$(dirname "$0") # gets the current path to the scripts directory
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

# Add startup script to the desktop's autostart to run on boot
AUTOSTART_PATH="/etc/xdg/lxsession/rpd-x/autostart"
if ! grep -q "@bash $SCRIPTS_DIR/startup.sh" "$AUTOSTART_PATH"; then
    echo "Adding startup script to autostart"
    echo "@bash $SCRIPTS_DIR/startup.sh" | sudo tee -a "$AUTOSTART_PATH" > /dev/null
else
    echo "Startup script already in autostart"
fi

echo "Initialization complete. Please reboot the Raspberry Pi to apply changes and start the Polypod application."