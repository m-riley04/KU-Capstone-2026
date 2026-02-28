#!/bin/bash
set -euo pipefail

CFG="/boot/firmware/config.txt"

echo "[ws35g] Provisioning Waveshare 3.5in LCD (G)"

# Install firmware blob
mkdir -p /tmp/ws35g && cd /tmp/ws35g
wget -nv -O St7796s.zip https://files.waveshare.com/wiki/common/St7796s.zip
unzip -o St7796s.zip
if [[ -f st7796s.bin ]]; then
  install -d /lib/firmware
  install -m 0644 st7796s.bin /lib/firmware/st7796s.bin
  echo "[ws35g] Installed st7796s.bin to /lib/firmware/"
fi

# --------------------------------------------------------------------------
# CRITICAL: dtparam=spi=on MUST appear BEFORE any dtoverlay= lines in
# config.txt. After a dtoverlay line, dtparam applies to THAT overlay
# instead of being global. We inject it near the top of the file.
# --------------------------------------------------------------------------
if ! grep -q '^dtparam=spi=on' "${CFG}" 2>/dev/null; then
  echo "[ws35g] Injecting dtparam=spi=on at top of config.txt"
  if grep -q '^\[all\]' "${CFG}"; then
    sed -i '/^\[all\]/a dtparam=spi=on' "${CFG}"
  else
    sed -i '1i dtparam=spi=on' "${CFG}"
  fi
fi

# SPI display overlay block
TITLE="#---- Waveshare 3.5in G Display (SPI) ----"
read -r -d '' BLOCK <<'CFGEOF' || true
#---- Waveshare 3.5in G Display (SPI) ----
dtoverlay=mipi-dbi-spi,speed=48000000
dtparam=compatible=st7796s\0panel-mipi-dbi-spi
dtparam=width=320,height=480,width-mm=49,height-mm=79
dtparam=reset-gpio=27,dc-gpio=22,backlight-gpio=18
dtoverlay=ads7846,speed=2000000,penirq=17,xmin=300,ymin=300,xmax=3900,ymax=3800,pmin=0,pmax=65535,xohms=400
extra_transpose_buffer=2
CFGEOF

mkdir -p "$(dirname "${CFG}")"
touch "${CFG}"
if ! grep -qF "${TITLE}" "${CFG}"; then
  printf "\n%s\n" "${BLOCK}" >> "${CFG}"
fi

# Auto-load the panel-mipi-dbi kernel module at boot.
# The device-tree overlay tells the kernel what hardware exists, but the
# driver module is not built-in — it must be explicitly loaded.
echo "[ws35g] Enabling panel-mipi-dbi module autoload"
echo "panel-mipi-dbi" > /etc/modules-load.d/spi-display.conf

echo "[ws35g] Done."