#!/bin/bash

# This script launches the Polypod application in release mode.

echo "Date: $(date)"
echo "PATH: $PATH"
echo "Flutter path: $(whereis flutter)"
echo "Launching Polypod application in release mode..."

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
flutter run --release

echo "Polypod application has exited. Check launch.log for output and errors."