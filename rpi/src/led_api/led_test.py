from RPi import GPIO  # type: ignore

# These pin numbers are based on the board's numbering scheme
# good website: https://pinout.xyz/
PIN_LED_RED = 40 # aka GPIO 21
PIN_LED_GREEN = 38 # aka GPIO 20
PIN_LED_BLUE = 36 # aka GPIO 16

def setup():
    """
    Sets up the GPIO pins for the RGB LED. This function should be called before using the LED functions.
    """
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(PIN_LED_RED, GPIO.OUT)
    GPIO.setup(PIN_LED_BLUE, GPIO.OUT)
    GPIO.setup(PIN_LED_GREEN, GPIO.OUT)

def set_led_color(red: bool, blue: bool, green: bool):
    """
    Set the color of the RGB LED by controlling the state of each color pin.
    :param red: If True, the red LED will be on; otherwise, it will be off.
    :param blue: If True, the blue LED will be on; otherwise, it will be off.
    :param green: If True, the green LED will be on; otherwise, it will be off.
    """
    GPIO.output(PIN_LED_RED, GPIO.HIGH if red else GPIO.LOW)
    GPIO.output(PIN_LED_BLUE, GPIO.HIGH if blue else GPIO.LOW)
    GPIO.output(PIN_LED_GREEN, GPIO.HIGH if green else GPIO.LOW)

def run_led_test():
    """
    Runs a simple test to cycle through the colors of the RGB LED. This function will block until the user interrupts it.
    """
    print("Starting LED test. Press Ctrl+C to exit.")
    try:
        while True:
            print("Setting LED to Red...")
            set_led_color(red=True, blue=False, green=False)
            input("Press Enter to continue...")

            print("Setting LED to Blue...")
            set_led_color(red=False, blue=True, green=False)
            input("Press Enter to continue...")

            print("Setting LED to Green...")
            set_led_color(red=False, blue=False, green=True)
            input("Press Enter to continue...")
    except KeyboardInterrupt:
        pass
    finally:
        GPIO.cleanup()

def main():
    setup()
    run_led_test()

if __name__ == "__main__":
    main()
