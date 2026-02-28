[Unit]
Description=Polypod Flutter App (sway dual-display)
After=multi-user.target network-online.target seatd.service
Wants=network-online.target seatd.service

[Service]
Type=simple
User=$POLYPOD_USER

# Sway needs a real VT
TTYPath=/dev/tty7
StandardInput=tty
StandardOutput=journal
StandardError=journal

# Wayland environment
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=tty
Environment=HOME=/home/$POLYPOD_USER
Environment=WLR_DRM_NO_ATOMIC=1

# Let systemd create XDG_RUNTIME_DIR
RuntimeDirectory=user/1000
RuntimeDirectoryMode=0700

ExecStart=/opt/polypod/scripts/startup.sh

Restart=on-failure
RestartSec=5

SupplementaryGroups=video render input

[Install]
WantedBy=multi-user.target
