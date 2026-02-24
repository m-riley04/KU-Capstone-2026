# Polypod Notification System

**Author:** Riley Anderson  
**Date:** February 17, 2026

## Overview

This system enables notifications from local machine or external APIs to be displayed as Flutter widgets on the top screen of the Polypod device. The system consists ofPython backend for receiving and processing notifications and a Flutter frontend for displaying them with custom configurations.

## Architecture

```
┌─────────────────┐
│  Notification   │ (JSON format)
│    Source       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   notify.py     │ ◄── Processes notification
│                 │     Applies source-specific config
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ current_        │ ◄── JSON file bridge
│ notification.   │
│ json            │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Notification    │ ◄── Monitors file for changes
│ Controller      │
│ (Dart)          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Notification    │ ◄── Displays on top screen
│ Overlay Widget  │     with animations
└─────────────────┘
```

## Components

### Python Backend

#### 1. `notify.py`
Main notification handler that:
- Validates incoming notification JSON
- Retrieves source-specific configuration
- Writes formatted notification to bridge file

**Functions:**
- `notify(notification_json)` - Main entry point for notifications
- `get_config_for_source(source)` - Returns configuration for source
- `send_to_flutter(payload)` - Writes to JSON bridge file

#### 2. `common_configs.py`
Configuration definitions for notification display:
- `MEDIA_SIZES` - Predefined media dimensions (none, small, medium, large, full)
- `TEXT_SIZES` - Font sizes (small, medium, large)
- `DefaultConfig` - Base configuration
- `NFLConfig` - Sports notifications (large media)
- `NASAConfig` - Science notifications (smaller info text)

#### 3. `base_notif.json`
Template showing expected notification structure:
```json
{
  "notifType": "base",
  "fromSource": "",
  "data": {
    "timestamp": "",
    "media": "",
    "headline": "",
    "info": "",
    "seemore": ""
  }
}
```

### Flutter Frontend

#### 1. `parse_to_widget.dart`
Core notification parsing and widget implementation:
- `NotificationConfig` - Configuration data model
- `NotificationData` - Notification data model
- `parseNotificationFromFile()` - Reads and parses JSON file
- `NotificationWidget` - Displays notification with custom styling

#### 2. `notification_controller.dart`
State management for notifications:
- Monitors `current_notification.json` for changes (500ms polling)
- Manages notification lifecycle
- Notifies listeners when new notification arrives
- Provides methods for clearing/dismissing notifications

#### 3. `notification_overlay.dart`
Display widget with animations:
- Slide-in animation from top
- Fade in/out transitions
- Auto-dismiss after 10 seconds
- Manual dismiss button
- "See More" button support

#### 4. Integration in `main.dart` and `top_screen.dart`
- `NotificationController` instantiated in main app state
- Overlay positioned at top of screen stack
- Receives updates automatically when Python writes new notification

## Notification Format

### Input (to `notify.py`)

```json
{
  "notifType": "base",
  "fromSource": "NFL|NASA|WeatherAPI|etc",
  "data": {
    "timestamp": "2026-02-17T10:30:00Z",
    "media": "url_or_path_to_image",
    "headline": "Main notification text",
    "info": "Additional details",
    "seemore": "url_for_qr_code"
  }
}
```

### Bridge File (written by Python, read by Dart)

```json
{
  "notification": {
    "timestamp": "2026-02-17T10:30:00Z",
    "media": "",
    "headline": "Chiefs Win Super Bowl!",
    "info": "Kansas City Chiefs defeat the Eagles 31-28.",
    "seemore": "https://example.com/nfl"
  },
  "config": {
    "media_size": [256.0, 192.0],
    "headline_size": 36.0,
    "info_size": 24.0
  },
  "from_source": "NFL"
}
```

## Usage

### Sending a Notification (Python)

```python
from notify import notify

notification = {
    "notifType": "base",
    "fromSource": "NFL",  # or "NASA", "", etc.
    "data": {
        "timestamp": "2026-02-17T10:30:00Z",
        "media": "",
        "headline": "Chiefs Win Super Bowl!",
        "info": "Kansas City Chiefs defeat the Eagles 31-28.",
        "seemore": "https://example.com/details"
    }
}

notify(notification)
```

### Running Test Notifications

```bash
cd rpi/src/notif
python test_notifications.py
```

This will send a series of test notifications demonstrating:
- Default configuration
- NFL configuration (large media)
- NASA configuration (smaller text)
- Custom API (default config)

### Flutter App Display

The notification will automatically appear on the top screen with:
- Source label (e.g., "NFL" in cyan)
- Media image (if provided, sized per config)
- Headline (large bold text)
- Info text (medium size)
- Timestamp (small gray text)
- "See More" button (if URL provided)
- Close button (top-right corner)

## Adding New Source Configurations

To add a custom configuration for a new API:

1. **Add to `COMMON_CONFIGS` list** in `common_configs.py`:
   ```python
   COMMON_CONFIGS = ['NFL', 'NASA', 'MyNewAPI']
   ```

2. **Create configuration class**:
   ```python
   class MyNewAPIConfig():
       media_size = MEDIA_SIZES.full  # Choose size
       headline_size = TEXT_SIZES.large
       info_size = TEXT_SIZES.small
   ```

3. **Update `get_config_for_source()`** in `notify.py`:
   ```python
   elif source == 'MyNewAPI':
       from common_configs import MyNewAPIConfig
       return MyNewAPIConfig()
   ```

## File Structure

```
rpi/src/
├── notif/
│   ├── notify.py                    # Main Python handler
│   ├── common_configs.py            # Configuration definitions
│   ├── base_notif.json              # Template
│   ├── parse_to_widget.dart         # Dart parsing & widget
│   ├── current_notification.json    # Bridge file (generated)
│   └── test_notifications.py        # Testing script
│
└── polypod_hw/lib/
    ├── main.dart                    # App entry (integrates controller)
    ├── controllers/
    │   └── notification_controller.dart  # State management
    ├── widgets/
    │   └── notification_overlay.dart     # Display widget
    └── screens/
        └── top_screen.dart          # Integration point
```

## Troubleshooting

### Notifications not appearing:
1. Check that `current_notification.json` is being created in `rpi/src/notif/`
2. Verify Flutter app has read permissions for the file
3. Check Flutter console for parsing errors
4. Ensure notification controller is properly initialized in main.dart

### Configuration not applied:
1. Verify source name exactly matches entry in `COMMON_CONFIGS`
2. Check that config class is imported in `get_config_for_source()`
3. Confirm config values are properly formatted (tuples for sizes)

### File path issues:
- Update `notificationFilePath` in `NotificationController` if running from different directory
- Use absolute paths for testing

## Testing

1. Start the Flutter app:
   ```bash
   cd rpi/src/polypod_hw
   flutter run
   ```

2. Run test notifications:
   ```bash
   cd rpi/src/notif
   python test_notifications.py
   ```

3. Observe notifications appearing on the top screen with different configurations