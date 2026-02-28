# Polypod Kiosk Image Builder

Custom Raspberry Pi 5 image for a dual-display Flutter kiosk using `rpi-image-gen`.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              systemd → greetd                    │
│                    ↓                             │
│              start-sway.sh                       │
│         (reads /etc/polypod/polypod.conf)        │
│                    ↓                             │
│           ┌── Sway Compositor ──┐                │
│           │  WLR_DRM_DEVICES=   │                │
│           │  card1:card0        │                │
│           │                     │                │
│  ┌────────┴───────┐  ┌─────────┴──────┐         │
│  │  DSI-2 / HDMI  │  │  SPI-1 / HDMI  │         │
│  │  640×480       │  │  320×480       │         │
│  │                │  │                │         │
│  │ flutter-elinux │  │ flutter-elinux │         │
│  │ (Wayland)      │  │ (Wayland)      │         │
│  │                │  │                │         │
│  │ Polypod_Top_   │  │ Polypod_Bottom │         │
│  │ Window         │  │ _Window        │         │
│  └────────────────┘  └────────────────┘         │
│           ↕ IPC (Unix socket)  ↕                 │
│      /opt/polypod/shared/polypod.sock            │
└─────────────────────────────────────────────────┘
```

**Displays:**
- **Top**: Waveshare 3.5" DSI LCD (E) — 640×480, capacitive touch, MIPI DSI
- **Bottom**: Waveshare 3.5" RPi LCD (G) — 320×480, resistive touch, SPI
- **HDMI**: Hot-pluggable, substitutes for either display in dev mode

**Compositor**: Sway (Wayland) manages all outputs and assigns Flutter windows by `app_id`.

**Flutter**: `flutter-elinux` (Sony) running as Wayland clients.

## File Structure

```
polypod-image/
├── build.sh                                    # Build entry point
├── config/
│   └── polypod-kiosk.yaml                      # rpi-image-gen top-level config
├── overlays/                                   # Cached .dtbo files (git-ignored)
│   └── Waveshare_35DSI.dtbo
├── firmware/                                   # Cached firmware binaries
│   └── st7796s.bin
├── layer/polypod/
│   ├── polypod.yaml                            # Layer definition (packages + hooks)
│   └── rootfs-overlay/                         # Files copied verbatim into image
│       ├── boot/firmware/
│       │   ├── config.txt                      # dtoverlays for both displays
│       │   └── overlays/                       # .dtbo files placed here
│       ├── etc/
│       │   ├── greetd/config.toml              # Auto-login → Sway
│       │   ├── polypod/polypod.conf            # ★ Central configuration
│       │   ├── systemd/system/
│       │   │   ├── polypod-setup.service       # First-boot hardware detection
│       │   │   ├── app-update.service          # OTA pull
│       │   │   └── app-update.timer            # Hourly OTA check
│       │   └── udev/rules.d/
│       │       └── 99-waveshare-touch.rules    # Touch device permissions
│       ├── home/pi/.config/
│       │   ├── sway/config                     # Compositor + window rules
│       │   └── systemd/user/
│       │       ├── polypod-top.service          # Top Flutter app (restart on crash)
│       │       ├── polypod-bottom.service       # Bottom Flutter app
│       │       └── polypod-bottom-spi.service   # SPI fallback mode
│       └── usr/local/bin/
│           ├── start-sway.sh                   # greetd → Sway launcher
│           ├── polypod-setup-system.sh         # Boot-time hardware detection
│           ├── polypod-identify-displays.sh    # Display enumeration + touch mapping
│           ├── polypod-deploy.sh               # App deployment + rollback
│           ├── polypod-update.sh               # Remote update puller
│           └── polypod-spi-fallback.sh         # Direct SPI DRM rendering
└── scripts/                                    # Extra build-time scripts
```

## Prerequisites

On your **build machine** (x86_64 Linux):

```bash
# Install rpi-image-gen
git clone https://github.com/raspberrypi/rpi-image-gen.git
cd rpi-image-gen
# Follow their install instructions (needs mmdebstrap, qemu-user-static, etc.)

# Install flutter-elinux (for cross-compiling Flutter apps)
flutter pub global activate flutter-elinux
```

## Building the Image

### Quick build (defaults)

```bash
cd polypod-image
chmod +x build.sh
./build.sh --password 'YourSecurePassword'
```

### Development build (no DSI display, uses HDMI)

```bash
./build.sh --dev-mode --debug --password 'dev123'
```

### Build with SPI fallback (if Sway can't handle SPI DRM)

```bash
./build.sh --spi-fallback --password 'dev123'
```

### Build with only HDMI (no SPI, no DSI)

```bash
./build.sh --no-spi --no-dsi --password 'dev123'
```

### Pre-cache overlay files (for offline/faster builds)

```bash
./build.sh --cache-overlays
# Then build normally — cached files are used automatically
./build.sh
```

### Dry run (see what would happen)

```bash
./build.sh --dev-mode --spi-fallback --dry-run
```

### Override rpi-image-gen settings

```bash
./build.sh -- IGconf_device_hostname=polypod-test IGconf_image_name=test-build
```

## Flashing

```bash
# Find your SD card
lsblk

# Flash (replace /dev/sdX)
sudo dd if=work/polypod-kiosk.img of=/dev/sdX bs=4M status=progress
sync

# Or use Raspberry Pi Imager (select "Use custom" and pick the .img)
```

## Deploying Flutter Apps

### Build your Flutter apps (on dev machine)

```bash
# Top window
cd polypod_top_window/
flutter-elinux build elinux --target-arch=arm64 --target-backend-type=wayland
# Output: build/elinux/arm64/release/bundle/

# Bottom window
cd polypod_bottom_window/
flutter-elinux build elinux --target-arch=arm64 --target-backend-type=wayland
```

### Deploy to device

```bash
# Method 1: rsync (recommended)
rsync -az ./polypod_top_window/build/elinux/arm64/release/bundle/ \
    pi@polypod:/opt/polypod/top/
rsync -az ./polypod_bottom_window/build/elinux/arm64/release/bundle/ \
    pi@polypod:/opt/polypod/bottom/

# Restart apps
ssh pi@polypod polypod-deploy.sh --restart

# Method 2: Use the deploy helper (from dev machine)
scp deploy-to-device.sh pi@polypod:/usr/local/bin/
ssh pi@polypod polypod-deploy.sh /opt/polypod/.staging/top /opt/polypod/.staging/bottom
```

### Rollback

```bash
ssh pi@polypod polypod-deploy.sh --rollback-top
ssh pi@polypod polypod-deploy.sh --rollback-all
```

## Configuration (Without Rebuilding)

All runtime configuration lives in `/etc/polypod/polypod.conf`. SSH in and edit:

```bash
ssh pi@polypod
sudo nano /etc/polypod/polypod.conf
```

### Common changes

| Setting | What it does |
|---|---|
| `POLYPOD_TOP_OUTPUT="HDMI-A-1"` | Route top window to HDMI |
| `POLYPOD_BOTTOM_OUTPUT="HDMI-A-2"` | Route bottom window to HDMI |
| `POLYPOD_HDMI_DEV_MODE="1"` | Use HDMI-A-1 instead of DSI-2 |
| `POLYPOD_SPI_FALLBACK="1"` | Bottom app renders directly to SPI DRM |
| `POLYPOD_TOP_TRANSFORM="90"` | Rotate top display 90° |
| `POLYPOD_DEBUG="1"` | Verbose logging to /tmp/sway.log |
| `POLYPOD_UPDATE_ENABLED="1"` | Enable hourly auto-updates |

After editing, reboot or restart Sway:

```bash
sudo systemctl restart greetd
```

## Debugging

### Check display status

```bash
# DRM connectors
cat /sys/class/drm/card*-*/status

# Sway outputs (while Sway is running)
swaymsg -t get_outputs | jq '.[] | {name, active, current_mode}'

# Visual identification (shows output name on each display)
polypod-identify-displays.sh --label
```

### Check app status

```bash
systemctl --user status polypod-top
systemctl --user status polypod-bottom
journalctl --user -u polypod-top -f       # Follow logs
journalctl --user -u polypod-bottom -f
```

### Check Sway logs

```bash
cat /tmp/sway.log
# With POLYPOD_DEBUG=1, this includes Wayland protocol trace
```

### Emergency keyboard shortcuts (plug in a USB keyboard)

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+Backspace` | Kill Sway (returns to login) |
| `Ctrl+Alt+T` | Open terminal |
| `Ctrl+Alt+R` | Reload Sway config |
| `Ctrl+Alt+I` | Show output names on displays |

### Test touch input

```bash
# List input devices
libinput list-devices

# Watch touch events
evtest /dev/input/polypod-touch-top
evtest /dev/input/polypod-touch-bottom

# Check Sway input mapping
swaymsg -t get_inputs | jq '.[] | select(.type=="touch")'
```

### SPI display not showing up?

```bash
# Check if mipi-dbi-spi driver loaded
dmesg | grep -i "mipi\|spi\|st7796\|panel"

# Check DRM devices
ls -la /dev/dri/
cat /sys/class/drm/card*/device/driver 2>/dev/null

# Check if firmware loaded
dmesg | grep firmware

# Try SPI fallback mode
sudo sed -i 's/POLYPOD_SPI_FALLBACK="0"/POLYPOD_SPI_FALLBACK="1"/' /etc/polypod/polypod.conf
sudo systemctl restart greetd
```

### HDMI not detected?

```bash
# Check kernel parameters
cat /proc/cmdline | tr ' ' '\n' | grep -i "video\|hotplug"

# Force re-detect
cat /sys/class/drm/card*-HDMI-A-1/status

# Verify cmdline.txt has the D flag
cat /boot/firmware/cmdline.txt
# Should contain: video=HDMI-A-1:1920x1080M@60D vc4.force_hotplug=1
```

## SPI Display + Sway: Known Risks

The mipi-dbi-spi driver creates a separate DRM card. Sway uses `WLR_DRM_DEVICES` to
manage multiple cards — it renders on the primary GPU and copies framebuffers to secondary
devices. This **should** work but is less tested than single-card setups.

**If Sway doesn't recognize the SPI display:**
1. Set `POLYPOD_SPI_FALLBACK="1"` in polypod.conf
2. The bottom app will render directly to the SPI DRM device, bypassing Sway
3. Touch input for the SPI display will need manual `libinput` handling

**If the SPI display works in Sway** (check `swaymsg -t get_outputs`):
- Keep `POLYPOD_SPI_FALLBACK="0"` (default)
- Sway handles window placement and touch mapping automatically

## OTA Updates

### Manual push (simplest)

```bash
# From dev machine
rsync -az ./build/top/    pi@polypod:/opt/polypod/top/
rsync -az ./build/bottom/ pi@polypod:/opt/polypod/bottom/
ssh pi@polypod polypod-deploy.sh --restart
```

### Automatic pull (needs server)

1. Set up an rsync-accessible server with your builds
2. Edit polypod.conf:
   ```
   POLYPOD_UPDATE_ENABLED="1"
   POLYPOD_UPDATE_SERVER="your.server.com"
   POLYPOD_UPDATE_USER="deploy"
   POLYPOD_UPDATE_PATH="/releases/latest"
   ```
3. Builds are checked hourly and deployed automatically

### Full system updates

For OS-level updates, consider [Mender](https://mender.io) or [RAUC](https://rauc.io)
with A/B partition schemes. These are beyond the scope of this image builder but can be
layered on top.
