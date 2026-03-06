"""
Name: led_set_color.py
Description: One-shot script invoked by the Flutter UI to set the RGB LED color.
    GPIO pins hold their state after being set, so no persistent process is needed.
    Usage: python3 led_set_color.py <COLOR>
    where COLOR is one of: OFF, WHITE, RED, GREEN, BLUE, YELLOW, CYAN, MAGENTA
Author: Riley Meyerkorth
Creation Date: 05 March 2026
"""

import sys

from src.controller import LEDController
from src.enums import LEDColor


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 led_set_color.py <COLOR>")
        print(f"  Colors: {', '.join(c.name for c in LEDColor)}")
        sys.exit(1)

    color_name = sys.argv[1].upper()

    try:
        color = LEDColor[color_name]
    except KeyError:
        print(f"Unknown color '{color_name}'.")
        print(f"  Supported: {', '.join(c.name for c in LEDColor)}")
        sys.exit(1)

    controller = LEDController()
    controller.setColor(color)
    print(f"LED set to {color.name}")
    # NOTE: we intentionally do NOT call controller.cleanup() here.
    # cleanup() resets the GPIO pins, which would turn the LED off.
    # The pins hold their output state after the process exits.


if __name__ == "__main__":
    main()
