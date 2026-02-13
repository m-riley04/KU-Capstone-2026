#!/bin/bash
# Sets up the bottom display (Waveshare 3.5" 480x320 LCD G resistive touch) drivers and config

# NOTE: The following is the "Bookworm System Desktop Display" configuration from the Waveshare wiki:
# https://www.waveshare.com/wiki/3.5inch_RPi_LCD_(G)
# We use DietPi, which uses 13.3 (Trixie).
# The wiki doesn't give explicit instructions for Trixie, but it should be similar to Bookworm.

# Copy driver firmware to /lib/firmware
# NOTE: I'm not sure if this is necessary, but the wiki instructions say to do it.
cd /tmp
wget https://files.waveshare.com/wiki/common/St7796s.zip -O St7796s.zip -nc
unzip -o St7796s.zip
sudo cp st7796s.bin /lib/firmware/

# Add options section to config.txt
# NOTE: This is the most important part. If this config is not added, the display does not light.
OPTIONS_TITLE="#---- Waveshare 3.5in G Display ----"
OPTIONS="$OPTIONS_TITLE
dtparam=spi=on
dtoverlay=mipi-dbi-spi,speed=48000000
dtparam=compatible=st7796s\0panel-mipi-dbi-spi
dtparam=width=320,height=480,width-mm=49,height-mm=79
dtparam=reset-gpio=27,dc-gpio=22,backlight-gpio=18
dtoverlay=ads7846,speed=2000000,penirq=17,xmin=300,ymin=300,xmax=3900,ymax=3800,pmin=0,pmax=65535,xohms=400
extra_transpose_buffer=2"

# Add display configuration to /boot/firmware/config.txt ONLY IF it doesn't exist yet
# NOTE: a bit hacky, but should work for now. Maybe can parse more robustly later.
if ! grep -q "$OPTIONS_TITLE" /boot/firmware/config.txt; then
    echo "$OPTIONS" | sudo tee -a /boot/firmware/config.txt > /dev/null
else
    echo "Display configuration already exists in config.txt, skipping."
fi

