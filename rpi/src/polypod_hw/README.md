# Polypod Hardware UI

This is the directory that holds the UI running natively on the Raspberry Pi. It runs on Flutter (dart).

## Setup

### Environment

Visual Studio Code is the easiest IDE to use and install Flutter.

1. Install Visual Studio Code.
2. Install the official Flutter extension for VS Code.
3. After installing the extension, accept the prompt to install the Flutter SDK.

## Usage

1. Open the `rpi/src/polypod_hw` directory in VS Code.
2. Open the terminal in VS Code and run `flutter pub get` to install the dependencies.
3. Run the app using the debug options in VS Code or by using `flutter run` in the terminal.

Running the following commands in the terminal from the repo's root will also work:

```bash
cd rpi/src/polypod_hw
flutter pub get
flutter run
```

### Notes (usage)

- On first run, it should be done by using `flutter run` in the terminal. This will allow you to select the platform and install the dependencies/tools. After this, you can use the debug options in VS Code to run the app.
