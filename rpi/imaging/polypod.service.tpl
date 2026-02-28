[Unit]
Description=Polypod Flutter App (kiosk)
After=multi-user.target network-online.target seatd.service
Wants=network-online.target seatd.service

[Service]
Type=simple
User=$POLYPOD_USER

# Cage needs a real VT to render on
TTYPath=/dev/tty7
StandardInput=tty
StandardOutput=journal
StandardError=journal

# Wayland/DRM environment
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=tty
Environment=HOME=/home/$POLYPOD_USER

# Force cage to use SPI display (card0) instead of HDMI (card2)
# Adjust if `ls /sys/class/drm/` shows a different card for the G display
Environment=WLR_DRM_DEVICES=/dev/dri/card0

# Suppress non-fatal EGL warnings
Environment=WLR_DRM_NO_ATOMIC=1

# Let systemd create XDG_RUNTIME_DIR (avoids permission issues with mkdir)
RuntimeDirectory=user/1000
RuntimeDirectoryMode=0700

# Launch Flutter app inside Cage
ExecStart=/usr/bin/cage -s -- /opt/polypod/app/polypod_hw

Restart=on-failure
RestartSec=5

# GPU + input access
SupplementaryGroups=video render input

[Install]
WantedBy=multi-user.target
