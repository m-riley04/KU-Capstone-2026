#!/bin/bash
# Sets up Flutter

# NOTE: based on instructions from flutter docs

# Install dependencies
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa cmake ninja-build clang libgtk-3-dev mesa-utils

# get flutter sdk for linux arm64 from repo (no official downloads/releases for linux arm64)
mkdir -p ~/develop
cd ~/develop
git clone https://github.com/flutter/flutter.git

# add flutter to path
echo 'export PATH="$PATH:$HOME/develop/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# run flutter doctor to complete setup
flutter doctor
