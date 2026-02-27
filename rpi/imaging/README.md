# imaging

This folder is dedicated to storing [`rpi-image-gen`](https://github.com/raspberrypi/rpi-image-gen) project files for the polypod's dedicated OS image.

## Building

Please note that for the majority of our tests, we are using commit [5091ed8](https://github.com/raspberrypi/rpi-image-gen/commit/5091ed8628125f09bd6b66d5a6fa01d1e037a1c9) of `rpi-image-gen` and building on a Debian through WSL. There are some issues with this setup, so you must do the following before building:

1. Run `sudo apt update && sudo apt install `. These are dependencies that are required, but are not inside the `install_deps.sh` file that comes with `rpi-image-gen`
2. Run `sudo nano /etc/wsl.conf` and add the following to the bottom to fix a PATH issue:

```conf
[interop]
appendWindowsPath=false
```

After these steps are completed, you can then build the image by running the following:

```bash
mkdir -p ~/develop
git clone https://github.com/raspberrypi/rpi-image-gen
cd ~/develop/rpi-image-gen
git checkout 5091ed8
sudo ./install_deps.sh
./rpi-image-gen -S ~/develop/KU-Capstone-2026/imaging/ -c ~/develop/KU-Capstone-2026/imaging/config/polypod.yaml
```

> NOTE: This is assuming this repo is located next to `rpi-image-gen` in `~/develop`

## Splash Screen

The splash screen has a few requirements:

- Format should be TGA
- Resolution should be 1920x1080
- Depth should be 3
- Max color space should be 224

Using [ImageMagick](https://imagemagick.org/#gsc.tab=0), you can use the following command on Linux to convert an image of one format to TGA.

> NOTE: You will need to set your own `INPUT_IMAGE` and `OUTPUT_IMAGE` variables.

```bash
set INPUT_IMAGE=example.jpg # NOTE: this can be any extension
set OUTPUT_IMAGE=example.tga
convert $INPUT_IMAGE \
    -size 1920x1080 \
    -depth 8 \
    -colors 224 \
    -type truecolor \
    -flip \
    $OUTPUT_IMAGE
```
