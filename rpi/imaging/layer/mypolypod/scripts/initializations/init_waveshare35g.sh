#!/bin/bash
set -euo pipefail

CFG="/boot/firmware/config.txt"
TITLE="#---- Waveshare 3.5in G Display ----"
read -r -d '' BLOCK <<'EOF' || true
#---- Waveshare 3.5in G Display ----
dtparam=spi=on
dtoverlay=mipi-dbi-spi,speed=48000000
dtparam=compatible=st7796s\0panel-mipi-dbi-spi
dtparam=width=320,height=480,width-mm=49,height-mm=79
dtparam=reset-gpio=27,dc-gpio=22,backlight-gpio=18
dtoverlay=ads7846,speed=2000000,penirq=17,xmin=300,ymin=300,xmax=3900,ymax=3800,pmin=0,pmax=65535,xohms=400
extra_transpose_buffer=2
EOF

mkdir -p /tmp/ws35g
cd /tmp/ws35g
wget -nv -O St7796s.zip https://files.waveshare.com/wiki/common/St7796s.zip
unzip -o St7796s.zip

if [[ -f st7796s.bin ]]; then
  install -d /lib/firmware
  install -m 0644 st7796s.bin /lib/firmware/st7796s.bin
fi

mkdir -p "$(dirname "${CFG}")"
touch "${CFG}"
if ! grep -qF "${TITLE}" "${CFG}"; then
  printf "\n%s\n" "${BLOCK}" >> "${CFG}"
fi