#!/bin/bash

# This script will be run on the Raspberry Pi at startup to launch the Polypod application with flutter-pi.

POLYPOD_ROOT=$HOME/polypod/aarch64-generic

flutter-pi --videomode 480x320 -d "74,50" -r 270 $POLYPOD_ROOT