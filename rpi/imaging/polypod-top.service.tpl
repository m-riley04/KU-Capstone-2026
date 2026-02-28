[Unit]
Description=Polypod Top Display (SPI)
After=multi-user.target network-online.target seatd.service
Wants=network-online.target seatd.service

[Service]
Type=simple
User=$POLYPOD_USER

TTYPath=/dev/tty7
StandardInput=tty
StandardOutput=journal
StandardError=journal

Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=XDG_SESSION_TYPE=tty
Environment=HOME=/home/$POLYPOD_USER
Environment=WLR_DRM_NO_ATOMIC=1

RuntimeDirectory=user/1000
RuntimeDirectoryMode=0700

ExecStart=/opt/polypod/scripts/startup_top.sh

Restart=on-failure
RestartSec=5

SupplementaryGroups=video render input

[Install]
WantedBy=multi-user.target
