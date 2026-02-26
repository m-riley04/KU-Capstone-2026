"""
Name: led_test.py
Description: A simple test script to verify that the RGB LED is working correctly. Cycles through the supported colors with user input.
Author: Riley Meyerkorth
Creation Date: 24 February 2026
"""

from src.controller import LEDController

def main():
    """
    Runs a simple test to cycle through the colors of the RGB LED. This function will block until the user interrupts it.
    """
    c = LEDController()

    print("Starting LED test. Press Ctrl+C to exit.")
    try:
        while True:
            for color in c.supportedColors():
                name = color.name
                print(f"Setting LED to {name}...")
                c.setColor(color)
                input("Press Enter to continue...")
            print("Cycle complete. Starting over...")
    except KeyboardInterrupt:
        pass
    finally:
        c.cleanup()

if __name__ == "__main__":
    main()
