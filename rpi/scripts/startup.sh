#!/bin/bash

# This script will be run on the Raspberry Pi at startup to launch the Polypod application with flutter-pi.
# Basically just a wrapper so that the output of the app and script can be logged to a file for debugging purposes.
# This is because when the app is launched from the autostart directory, there is no terminal output.

# NOTE: Need to add flutter to PATH here because when script is run from the autostart directory, it doesn't have access to the environment variables set in .bashrc or .profile.
export PATH="$PATH:$HOME/develop/flutter/bin"
#alias flutter="$HOME/develop/flutter/bin/flutter" # for some reason adding it to PATH isn't enough

SCRIPTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPTS_DIR/launch.sh" > "$SCRIPTS_DIR/launch.log" 2>&1