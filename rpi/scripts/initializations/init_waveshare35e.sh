#!/bin/bash
# Structured from the wiki here: https://www.waveshare.com/wiki/3.5inch_DSI_LCD_(E)

# Add options section to config.txt
OPTIONS_TITLE="#---- Waveshare 3.5in DSI E Display ----"
OPTIONS="$OPTIONS_TITLE
dtoverlay=vc4-kms-v3d
#DSI1 Use
dtoverlay=waveshare_35DSI,35E,dsi1
#DSI0 Use
#dtoverlay=waveshare_35DSI,35E,dsi0" # TODO: check which DSI to use for our display. Also make sure this works with multiple displays.

# Copy overlay to /boot/overlays
cd /tmp
wget https://files.waveshare.com/wiki/common/Waveshare_35DSI.dtbo -O Waveshare_35DSI.dtbo -nc
sudo cp Waveshare_35DSI.dtbo /boot/overlays/

# Add display configuration to /boot/firmware/config.txt ONLY IF it doesn't exist yet
if ! grep -q "$OPTIONS_TITLE" /boot/firmware/config.txt; then
    echo "$OPTIONS" | sudo tee -a /boot/firmware/config.txt > /dev/null
else
    echo "Display configuration already exists in config.txt, skipping."
fi

