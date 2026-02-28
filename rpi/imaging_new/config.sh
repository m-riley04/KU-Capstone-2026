# =============================================================================
# Polypod — Sway Configuration
# ~/.config/sway/config
# =============================================================================
# This config is dynamically augmented by start-sway.sh which reads
# /etc/polypod/polypod.conf and sets environment variables before launch.
# =============================================================================

# --- Basics ---
set $mod Mod4
default_border none
titlebar_border_thickness 0
titlebar_padding 0
font pango:monospace 0
focus_follows_mouse no

# --- Hide cursor after 1 second (kiosk mode) ---
seat * hide_cursor 1000
seat * hide_cursor when-typing enable

# --- Disable all bar / status ---
bar {
    mode invisible
}

# --- Output configuration ---
# These are set by start-sway.sh via environment variables.
# The actual display names come from /etc/polypod/polypod.conf.
#
# Top display (DSI-2 or HDMI-A-1 in dev mode)
output $POLYPOD_TOP_OUTPUT {
    resolution $POLYPOD_TOP_RES
    transform $POLYPOD_TOP_TRANSFORM
    position 0 0
    bg #000000 solid_color
}

# Bottom display (SPI-1 or HDMI-A-2 in fallback)
output $POLYPOD_BOTTOM_OUTPUT {
    resolution $POLYPOD_BOTTOM_RES
    transform $POLYPOD_BOTTOM_TRANSFORM
    position 0 480
    bg #000000 solid_color
}

# --- HDMI hot-plug: accept any HDMI output that appears ---
# If an HDMI display is connected that isn't explicitly configured above,
# just enable it with defaults. This makes debugging easier.
output HDMI-A-1 {
    bg #222222 solid_color
    enable
}
output HDMI-A-2 {
    bg #222222 solid_color
    enable
}

# --- Window assignment rules ---
# Map each Flutter app to its designated output by app_id.
# app_id for flutter-elinux defaults to the binary filename.
assign [app_id="$POLYPOD_TOP_APP_ID"] output $POLYPOD_TOP_OUTPUT
assign [app_id="$POLYPOD_BOTTOM_APP_ID"] output $POLYPOD_BOTTOM_OUTPUT

# Force fullscreen on both app windows
for_window [app_id="$POLYPOD_TOP_APP_ID"] fullscreen enable
for_window [app_id="$POLYPOD_BOTTOM_APP_ID"] fullscreen enable

# --- Prevent screen blanking ---
exec swayidle -w timeout 0 ''

# --- Touch input mapping ---
# Map each touch device to its corresponding output.
# These are set by polypod-identify-displays.sh at boot.
# The sway IPC command is: input <identifier> map_to_output <output>
#
# DSI touch (Goodix GT911):
#   input "1046:911:Goodix_Capacitive_TouchScreen" map_to_output DSI-2
# SPI touch (ADS7846):
#   input "0:0:ADS7846_Touchscreen" map_to_output SPI-1
#
# These are applied dynamically by the identify script, but we include
# common defaults here:
input type:touch {
    events enabled
    drag enabled
    tap enabled
}

# --- Launch apps ---
# In non-fallback mode, Sway launches both Flutter apps.
# In SPI fallback mode, only the top app runs under Sway;
# the bottom app is launched separately by polypod-spi-fallback.sh.
#
# We use systemd user services for restart-on-crash capability.
# The actual exec is handled by the user services, triggered by
# graphical-session.target which Sway sets.
exec "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
exec "systemctl --user start graphical-session.target"

# --- Emergency key bindings (for debugging with a keyboard) ---
# Ctrl+Alt+Backspace = kill Sway (returns to greetd login)
bindsym Ctrl+Alt+BackSpace exec swaymsg exit
# Ctrl+Alt+T = open a terminal (if foot is installed)
bindsym Ctrl+Alt+t exec foot || alacritty || xterm
# Ctrl+Alt+R = reload Sway config
bindsym Ctrl+Alt+r reload
# Ctrl+Alt+I = identify outputs (shows output names on each display)
bindsym Ctrl+Alt+i exec /usr/local/bin/polypod-identify-displays.sh --label
