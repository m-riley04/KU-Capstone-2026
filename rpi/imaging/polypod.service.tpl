[Unit]
Description=Polypod Flutter App (kiosk)
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
Environment=WLR_BACKENDS=drm
Environment=WLR_DRM_NO_ATOMIC=1
Environment=XDG_SESSION_TYPE=tty
Environment=HOME=/home/$POLYPOD_USER

ExecStartPre=/bin/bash -c "mkdir -p /run/user/1000 && chown $POLYPOD_USER:$POLYPOD_USER /run/user/1000 && chmod 0700 /run/user/1000"
ExecStart=/usr/bin/cage -s -- /opt/polypod/app/polypod_hw

Restart=on-failure
RestartSec=5

SupplementaryGroups=video render input

[Install]
WantedBy=multi-user.target
