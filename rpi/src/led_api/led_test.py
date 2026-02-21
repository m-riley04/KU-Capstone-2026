from RPi import GPIO  # type: ignore
from enum import Enum

# These pin numbers are based on the board's numbering scheme
# good website: https://pinout.xyz/
PIN_LED_RED = 40 # aka GPIO 21
PIN_LED_GREEN = 38 # aka GPIO 20
PIN_LED_BLUE = 36 # aka GPIO 16

RGBColor = tuple[bool, bool, bool]  # (red, green, blue)

class LEDColor(Enum):
    """
    Represents the different colors that the RGB LED can display.
    Each color represented by a tuple of booleans (RGB) where True means the LED is on and False means it is off.
    TODO: Maybe could include digital potentiometer values for brightness control in the future? Could get way more complex colors.
    """
    OFF: RGBColor = (False, False, False)
    WHITE: RGBColor = (True, True, True)
    RED: RGBColor = (True, False, False)
    GREEN: RGBColor = (False, True, False)
    BLUE: RGBColor = (False, False, True)
    YELLOW: RGBColor = (True, True, False)
    CYAN: RGBColor = (False, True, True)
    MAGENTA: RGBColor = (True, False, True)

# a map of color names to their corresponding LEDColor enum values for easy access in the test function
RGB_COLORS = {
    "off": LEDColor.OFF
    , "white": LEDColor.WHITE
    , "red": LEDColor.RED
    , "green": LEDColor.GREEN
    , "blue": LEDColor.BLUE
    , "yellow": LEDColor.YELLOW
    , "cyan": LEDColor.CYAN
    , "magenta": LEDColor.MAGENTA
    }

def setup():
    """
    Sets up the GPIO pins for the RGB LED. This function should be called before using the LED functions.
    """
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(PIN_LED_RED, GPIO.OUT)
    GPIO.setup(PIN_LED_BLUE, GPIO.OUT)
    GPIO.setup(PIN_LED_GREEN, GPIO.OUT)

def set_led_color(color: LEDColor):
    """
    Set the color of the RGB LED by controlling the state of each color pin.
    :param color: The color to set the RGB LED to.
    """
    red, green, blue = color.value
    GPIO.output(PIN_LED_RED, GPIO.HIGH if red else GPIO.LOW)
    GPIO.output(PIN_LED_GREEN, GPIO.HIGH if green else GPIO.LOW)
    GPIO.output(PIN_LED_BLUE, GPIO.HIGH if blue else GPIO.LOW)


def run_led_test():
    """
    Runs a simple test to cycle through the colors of the RGB LED. This function will block until the user interrupts it.
    """
    print("Starting LED test. Press Ctrl+C to exit.")
    try:
        for name, color in RGB_COLORS.items():
            print(f"Setting LED to {name}...")
            set_led_color(color)
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
