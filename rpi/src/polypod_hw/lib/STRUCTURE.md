# Polypod Hardware GUI - Project Structure

## Overview
This Flutter project is configured for a dual-screen embedded device with two landscape-oriented screens:
- **Top Screen**: 640 × 480px - Display area for animations and status information
- **Bottom Screen**: 320 × 480px - Control interface with 6 square buttons

## Project Structure

```
lib/
├── main.dart                 # Application entry point and DualScreenHome widget
├── config/
│   └── screen_config.dart   # Screen dimensions and configuration constants
├── screens/
│   ├── top_screen.dart      # Top display screen with animations
│   └── bottom_screen.dart   # Bottom control screen with 6 buttons
└── widgets/
    └── control_button.dart  # Reusable control button widget
```

## Screen Configuration

All screen dimensions are defined in [config/screen_config.dart](lib/config/screen_config.dart):
- **Top Screen**: 640 × 480px (aspect ratio ~1.33:1)
- **Bottom Screen**: 320 × 480px (aspect ratio ~0.67:1)

Modify these constants to adjust screen sizes if needed.

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

## Running the Application

```bash
flutter run
```

The application will display both screens stacked vertically in the center of the display.

## Future Development

This modular structure is designed for easy expansion:
- Add new animation patterns to `TopScreen`
- Extend button functionality in `BottomScreen`
- Create additional screen layouts in the `screens/` directory
- Add app logic and state management in future iterations
