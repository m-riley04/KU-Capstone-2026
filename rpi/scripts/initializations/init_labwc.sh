#!/bin/bash
# Configures labwc compositor window rules for the Polypod dual-display setup.
#
# The Flutter app creates two windows:
#   "Polypod_Top_Screen"   → DSI-2 output (640×480 DSI display)
#   "Polypod_Bottom_Screen" → SPI-1 output (480×320 SPI display, rotated 90°)
#
# On Wayland, applications cannot position their own windows.  Instead the
# compositor (labwc) uses <windowRules> in rc.xml to move each window to the
# correct output and make it fullscreen when it first appears.

LABWC_DIR="$HOME/.config/labwc"
RC_XML="$LABWC_DIR/rc.xml"

RULE_MARKER="<!-- Polypod: place top screen on DSI display and fullscreen -->"

# Only patch if the rules aren't already present
if [ -f "$RC_XML" ] && grep -q "Polypod_Top_Screen" "$RC_XML"; then
    echo "labwc window rules for Polypod already present in $RC_XML, skipping."
    exit 0
fi

if [ ! -f "$RC_XML" ]; then
    echo "Error: labwc rc.xml not found at $RC_XML. Is labwc installed?"
    exit 1
fi

# Insert <windowRules> block just before the closing </openbox_config> tag.
# Using a temp file to avoid in-place sed issues.
WINDOW_RULES='<windowRules>\
'"$RULE_MARKER"'\
<windowRule title="Polypod_Top_Screen">\
<action name="MoveToOutput" output="DSI-2"/>\
<action name="ToggleFullscreen"/>\
</windowRule>\
<!-- Polypod: place bottom screen on SPI display and fullscreen -->\
<windowRule title="Polypod_Bottom_Screen">\
<action name="MoveToOutput" output="SPI-1"/>\
<action name="ToggleFullscreen"/>\
</windowRule>\
</windowRules>'

# Insert before </openbox_config>
sed -i "s|</openbox_config>|${WINDOW_RULES}</openbox_config>|" "$RC_XML"

echo "Added Polypod window rules to $RC_XML."
echo "labwc will pick them up on next restart (or run 'labwc --reconfigure')."
