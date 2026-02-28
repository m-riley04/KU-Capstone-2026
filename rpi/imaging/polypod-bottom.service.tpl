[Unit]
Description=Polypod Bottom Display (DSI)
After=multi-user.target network-online.target seatd.service polypod-top.service
Wants=network-online.target seatd.service

[Service]
Type=simple
User=$POLYPOD_USER

# Use tty8 (tty7 is used by the top display)
TTYPath=/dev/tty8
StandardInput=tty
StandardOutput=journal
StandardError=journal

Environment=XDG_RUNTIME_DIR=/run/user/1001
Environment=XDG_SESSION_TYPE=tty
Environment=HOME=/home/$POLYPOD_USER
Environment=WLR_DRM_NO_ATOMIC=1

RuntimeDirectory=user/1001
RuntimeDirectoryMode=0700

ExecStart=/opt/polypod/scripts/startup_bottom.sh

Restart=on-failure
RestartSec=5

SupplementaryGroups=video render input

[Install]
WantedBy=multi-user.target
