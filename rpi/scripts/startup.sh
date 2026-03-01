#!/bin/bash

# This script will be run on the Raspberry Pi at startup to launch the Polypod application with flutter-pi.

DEVELOP_DIR=$HOME/develop
REPO_DIR=$DEVELOP_DIR/KU-Capstone-2026
POLYPOD_UI_ROOT=$REPO_DIR/rpi/src/polypod_hw

# Error handling
if [ ! -d "$POLYPOD_UI_ROOT" ]; then
    echo "Error: Directory $POLYPOD_UI_ROOT does not exist."
    exit 1
fi

# TODO: add more error handling or dependency checking?

# Launch the Polypod application with flutter
cd $POLYPOD_UI_ROOT
flutter run