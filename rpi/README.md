# rpi

This directory contains all source code for the Raspberry Pi's setup and boot.

## Setup

To set up the Raspberry Pi from scratch, the following must be done:

### Formatting

The Raspberry Pi's miniSD card must be formatted using the [Raspberry Pi Imager](https://www.raspberrypi.com/software/). The following steps walk you through which options to select:

1. Insert the microSD card into your computer/laptop.
2. Launch Raspberry Pi Imager.
3. Select the "Raspberry Pi 5".
4. Click "Next".
5. Select the "Raspberry Pi OS (Other)" option from the list.
6. Scroll to near the bottom and select "Raspberry Pi OS (Legacy, 64 bit)" that is "Bookworm".
7. Click "Next".
8. Select the miniSD that you wish to format and put the OS on.
9. Click "Write".
10. Click "I understand, please erase and write" on the warning popup.
11. Wait for the device to begin formatting.
    - If a popup appears that says "You must format this disk", click "Format"
    - After you do this, a few warnings may appear. You can ignore these and close/accept them.
12. Wait for formatting to complete.
13. Click "Finish".

### Pi Setup

1. Assemble the Raspberry Pi 5 and components according to the documentation/architecture/pinouts.
2. Pull the repo into `~/dev/`
3. Run the initialization script [`init.sh`](scripts/init.sh)
4. Restart the pi

## Supplamental Reading

- [Official Waveshare 3.5in display docs](https://www.waveshare.com/wiki/3.5inch_RPi_LCD_(G))
