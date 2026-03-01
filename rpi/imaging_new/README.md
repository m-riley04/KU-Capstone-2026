# Polypod Kiosk Image Builder

Custom Raspberry Pi 5 image for a dual-display Flutter kiosk using `rpi-image-gen`.

## Architecture

```
Boot: systemd → greetd → start-sway.sh → Sway compositor

┌──────────────────── Sway (Wayland) ────────────────────┐
│                                                         │
│  ┌─── DSI-2 / HDMI-A-1 ───┐  ┌─── SPI-1 / HDMI-A-2 ─┐│
│  │  polypod_hw --window=top│  │ polypod_hw --window=bot││
│  │  (flutter-elinux)       │  │ (flutter-elinux)       ││
│  │  640×480                │  │ 320×480                ││
│  └─────────────────────────┘  └────────────────────────┘│
│               ↕ IPC (Unix socket) ↕                     │
│         /opt/polypod/shared/polypod.sock                │
└─────────────────────────────────────────────────────────┘

Window placement: polypod-place-windows.sh subscribes to Sway
window events via IPC and moves the 2nd window to the bottom output.
(Both processes share the same app_id since they're the same binary.)
```

**Displays:**
- **Top**: Waveshare 3.5" DSI LCD (E) — 640×480 capacitive touch, MIPI DSI
- **Bottom**: Waveshare 3.5" RPi LCD (G) — 320×480 resistive touch, SPI
- **HDMI**: Hot-pluggable, substitutes for either display in dev mode

**App source**: https://github.com/m-riley04/KU-Capstone-2026 (`rpi/src/polypod_hw`)

## File Structure

```
polypod-image/
├── build.sh                              # Image build entry point
├── build-flutter-apps.sh                 # Cross-compile Flutter app
├── deploy-to-device.sh                   # Dev machine → device push
├── config/
│   └── polypod-kiosk.yaml                # rpi-image-gen config
├── flutter-bundle/                       # Pre-built app (created by build-flutter-apps.sh)
├── .repo-cache/                          # Cloned polypod repo (cached)
├── overlays/                             # Cached .dtbo files
├── firmware/                             # Cached firmware binaries
└── layer/polypod/
    ├── polypod.yaml                      # Layer definition (packages + hooks)
    └── rootfs-overlay/
        ├── boot/firmware/config.txt      # dtoverlays for both displays
        ├── etc/
        │   ├── greetd/config.toml        # Auto-login → Sway
        │   ├── polypod/polypod.conf      # ★ Central config (edit without rebuild)
        │   ├── systemd/system/           # System services (setup, update timer)
        │   └── udev/rules.d/            # Touch device permissions
        ├── home/pi/.config/
        │   ├── sway/config               # Compositor + window rules
        │   └── systemd/user/             # polypod-top, polypod-bottom services
        └── usr/local/bin/
            ├── start-sway.sh             # greetd → Sway launcher
            ├── polypod-place-windows.sh  # IPC window placement daemon
            ├── polypod-setup-system.sh   # Boot-time hardware detection
            ├── polypod-identify-displays.sh
            ├── polypod-deploy.sh         # On-device deploy + rollback
            ├── polypod-update.sh         # Remote auto-update
            └── polypod-spi-fallback.sh   # Direct SPI DRM rendering
```

## Prerequisites (Build Machine, x86_64 Linux)

### 1. Install rpi-image-gen

```bash
git clone https://github.com/raspberrypi/rpi-image-gen.git
cd rpi-image-gen
# Follow their README for dependencies (mmdebstrap, qemu-user-static, etc.)
```

### 2. Install flutter-elinux

**This is NOT a pub package.** It's a standalone SDK fork:

```bash
# Install dependencies
sudo apt install curl unzip git clang cmake pkg-config

# Clone and install
git clone https://github.com/sony/flutter-elinux.git
sudo mv flutter-elinux /opt/
export PATH=$PATH:/opt/flutter-elinux/bin

# Add to your shell profile permanently
echo 'export PATH=$PATH:/opt/flutter-elinux/bin' >> ~/.bashrc

# Verify
flutter-elinux doctor
```

Or use the helper:
```bash
./build-flutter-apps.sh --install-flutter-elinux
```

## Building

### Step 1: Build the Flutter app

```bash
# From the polypod repo (default: main branch)
./build-flutter-apps.sh

# Or from a specific branch
./build-flutter-apps.sh --branch develop

# Or from your local checkout
./build-flutter-apps.sh --local ~/code/KU-Capstone-2026

# Reuse previously cloned repo (faster iteration)
./build-flutter-apps.sh --skip-clone
```

This creates `flutter-bundle/` containing the cross-compiled arm64 Wayland bundle.

### Step 2: Build the image

```bash
# Full build
./build.sh --password 'YourSecurePassword'

# Dev build (HDMI replaces DSI, debug logging)
./build.sh --dev-mode --debug --password 'dev123'

# Dev + SPI fallback (for when Sway can't handle SPI DRM)
./build.sh --dev-mode --spi-fallback --password 'dev123'

# All-in-one (build Flutter + build image)
./build.sh --build-flutter --password 'dev123'

# HDMI-only (no SPI, no DSI — pure development)
./build.sh --no-spi --no-dsi --password 'dev123'
```

### Step 3: Flash

```bash
sudo dd if=work/polypod-kiosk.img of=/dev/sdX bs=4M status=progress
# Or use Raspberry Pi Imager → "Use custom"
```

## Deploying App Updates (No Image Rebuild)

```bash
# From dev machine — build and push in one command
./deploy-to-device.sh ~/code/KU-Capstone-2026/rpi/src/polypod_hw

# Or manual rsync
cd ~/code/KU-Capstone-2026/rpi/src/polypod_hw
flutter-elinux pub get
flutter-elinux build elinux --target-arch=arm64 --target-backend-type=wayland --release
rsync -az build/elinux/arm64/release/bundle/ pi@polypod:/opt/polypod/app/
ssh pi@polypod polypod-deploy.sh --restart

# Rollback
ssh pi@polypod polypod-deploy.sh --rollback
```

## Configuration (No Rebuild Required)

SSH in and edit `/etc/polypod/polypod.conf`:

```bash
ssh pi@polypod
sudo nano /etc/polypod/polypod.conf
sudo systemctl restart greetd  # Apply changes
```

Key settings:

| Setting | Effect |
|---|---|
| `POLYPOD_HDMI_DEV_MODE="1"` | Top window → HDMI-A-1 (no DSI needed) |
| `POLYPOD_SPI_FALLBACK="1"` | Bottom app bypasses Sway, renders directly to SPI |
| `POLYPOD_TOP_OUTPUT="HDMI-A-1"` | Remap any output |
| `POLYPOD_TOP_ARGS="--window=top"` | Change CLI args passed to your app |
| `POLYPOD_DEBUG="1"` | Verbose logs in /tmp/sway.log |
| `POLYPOD_UPDATE_ENABLED="1"` | Enable hourly auto-updates |

## Debugging

```bash
# Display status
cat /sys/class/drm/card*-*/status
swaymsg -t get_outputs | jq '.[] | {name, active, current_mode}'
polypod-identify-displays.sh --label

# App logs
journalctl --user -u polypod-top -f
journalctl --user -u polypod-bottom -f

# Sway log
cat /tmp/sway.log

# Touch input
evtest /dev/input/polypod-touch-top
swaymsg -t get_inputs | jq '.[] | select(.type=="touch")'

# Check window placement
swaymsg -t get_tree | jq '.. | .app_id? // empty' | sort | uniq -c
```

**Keyboard shortcuts** (plug in USB keyboard):

| Shortcut | Action |
|---|---|
| `Ctrl+Alt+Backspace` | Kill Sway |
| `Ctrl+Alt+T` | Terminal |
| `Ctrl+Alt+R` | Reload Sway config |
| `Ctrl+Alt+I` | Label outputs |

## SPI + Sway: Dual-Path Strategy

The `mipi-dbi-spi` driver creates a separate DRM card. Sway can manage it via `WLR_DRM_DEVICES`, but this is less tested.

**Default** (`SPI_FALLBACK=0`): Sway manages both. Check `swaymsg -t get_outputs` for `SPI-1`.

**Fallback** (`SPI_FALLBACK=1`): Bottom app renders directly to SPI DRM, bypassing Sway.

Since you only have the G (SPI) display right now:
```bash
./build.sh --dev-mode --spi-fallback --debug --password 'dev123'
```
This puts Top → HDMI-A-1, Bottom → direct SPI.
