# Polypod Hardware GUI - Project Structure

## Overview
This Flutter project is configured for a dual-screen embedded device with two landscape-oriented screens:
- **Top Screen**: 640 × 480px - Display area for animations and status information
- **Bottom Screen**: 320 × 480px - Control interface with 6 square buttons

## Project Structure

```
lib/
├── main.dart                 # Application entry point and window routing
├── config/
│   ├── screen_config.dart   # Screen dimensions and configuration constants
│   ├── theme_config.dart    # Colour palette and theming
│   └── ipc_config.dart      # IPC port configuration
├── ipc/
│   ├── ipc.dart             # Barrel export for the IPC layer
│   ├── ipc_message.dart     # Message types and JSON serialisation
│   ├── ipc_server.dart      # TCP server (runs in the top-window process)
│   └── ipc_client.dart      # TCP client (runs in the bottom-window process)
├── multi_window/
│   ├── multi_window.dart    # Conditional import entry point
│   ├── multi_window_desktop.dart  # desktop_multi_window implementation
│   └── multi_window_stub.dart     # Unsupported-platform stub
├── controllers/
│   ├── clock_timer_controller.dart
│   ├── idle_state_controller.dart
│   └── notification_controller.dart
├── models/
│   └── notification_models.dart
├── apps/
│   ├── base_app.dart        # Abstract base for all apps
│   ├── idle_app.dart
│   ├── home_app.dart
│   ├── clock_app.dart
│   ├── weather_app.dart
│   ├── media_app.dart
│   ├── notes_app.dart
│   └── settings_app.dart
├── screens/
│   ├── top_screen.dart      # Top display screen with animations
│   └── bottom_screen.dart   # Bottom control screen with 6 buttons
└── widgets/
    ├── control_button.dart  # Reusable control button widget
    └── notification_overlay.dart
```

## Screen Configuration

All screen dimensions are defined in [config/screen_config.dart](lib/config/screen_config.dart):
- **Top Screen**: 640 × 480px (aspect ratio ~1.33:1)
- **Bottom Screen**: 320 × 480px (aspect ratio ~0.67:1)

Modify these constants to adjust screen sizes if needed.

## IPC (Inter-Process Communication)

The top and bottom windows communicate over a **TCP socket on localhost** (default port `9473`, configurable via `POLYPOD_IPC_PORT`).

| Direction | Message | Payload |
|-----------|---------|---------|
| bottom → top | `selectApp` | `{ "appName": "Timer" }` |
| bottom → top | `home` | — |
| bottom → top | `timerSelection` | `{ "hours", "minutes", "seconds" }` |
| bottom → top | `timerStart` | — |
| bottom → top | `timerPause` | — |
| bottom → top | `timerReset` | — |
| top → bottom | `appChanged` | `{ "currentAppKey": "Timer" }` |

Messages are newline-delimited JSON (`\n`).

### Architecture

- **Top-window process** starts an `IpcServer` that listens for connections.
- **Bottom-window process** creates an `IpcClient` that connects to the server.
  The client auto-reconnects if the connection drops.
- Both can run in the **same OS process** (`--single` flag) or as
  **separate processes** (default behaviour).

## Running the Application

### Separate-process mode (default / production / kiosk)

Launch two instances in separate terminals, one per display:

```bash
# Terminal 1 – top screen (starts IPC server) — this is the default
flutter run --dart-define=POLYPOD_WINDOW=top

# Terminal 2 – bottom screen (connects as IPC client)
flutter run --dart-define=POLYPOD_WINDOW=bottom
```

With a compiled binary (e.g. on the Raspberry Pi), use CLI args instead:

```bash
./polypod_hw           # top (default)
./polypod_hw --bottom  # bottom
```

### Single-process mode (development)

```bash
flutter run --dart-define=POLYPOD_WINDOW=single
```

Both screens display stacked vertically in one window. Useful for quick iteration.

In the sway kiosk config each `exec` line targets a different output.

## Components

### Top Screen (`top_screen.dart`)
- Displays rotating and scaling animations
- Shows the last button pressed from the control screen
- Dark background with cyan animated element
- Extensible for custom animation implementations

### Bottom Screen (`bottom_screen.dart`)
- Contains a 3×2 grid of square control buttons (6 total)
- Each button is color-coded
- Buttons are responsive with visual feedback
- Communicates button presses to the main application state

### Control Button Widget (`control_button.dart`)
- Reusable button component with:
  - Visual press feedback
  - Shadow effects
  - Customizable colors and labels
  - Touch-friendly interactions

## Future Development

This modular structure is designed for easy expansion:
- Add new animation patterns to `TopScreen`
- Extend button functionality in `BottomScreen`
- Create additional screen layouts in the `screens/` directory
- Add app logic and state management in future iterations
- Add new IPC message types in `ipc_message.dart` to support new inter-window features
