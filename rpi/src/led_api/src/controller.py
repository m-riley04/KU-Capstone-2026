"""
Name: controller.py
Description: The main controller for the RGB LED. This class provides functions to set the color of the LED and to clean up the GPIO pins when the program is exiting.
Author: Riley Meyerkorth
Creation Date: 24 February 2026
"""

from RPi import GPIO # type: ignore
from src.constants import PIN_LED_BLUE, PIN_LED_GREEN, PIN_LED_RED
from src.enums import LEDColor

class LEDController:
    """
    The main class to control the LEDs for the polypod.
    """

    def __init__(self, red_pin=PIN_LED_RED, green_pin=PIN_LED_GREEN, blue_pin=PIN_LED_BLUE):
        self._redPin = red_pin
        self._greenPin = green_pin
        self._bluePin = blue_pin

        self._color: LEDColor = LEDColor.OFF

        self._setup()

    def _setup(self):
        """
        Sets up the GPIO pins for the RGB LED. This function should be called before using the LED functions.
        """
        GPIO.setmode(GPIO.BOARD)
        GPIO.setup(self._redPin, GPIO.OUT)
        GPIO.setup(self._bluePin, GPIO.OUT)
        GPIO.setup(self._greenPin, GPIO.OUT)

    def cleanup(self):
        """
        Cleans up the GPIO pins. This function should be called when the program is exiting to ensure that the GPIO pins are reset to a safe state.
        """
        GPIO.cleanup()

    def color(self) -> LEDColor:
        """
        Get the current color of the RGB LED.
        :return: The current color of the RGB LED.
        """
        return self._color

    def setColor(self, color: LEDColor):
        """
        Set the color of the RGB LED by controlling the state of each color pin.
        :param color: The color to set the RGB LED to.
        """
        self._color = color
        red, green, blue = color.value
        GPIO.output(self._redPin, GPIO.HIGH if red else GPIO.LOW)
        GPIO.output(self._greenPin, GPIO.HIGH if green else GPIO.LOW)
        GPIO.output(self._bluePin, GPIO.HIGH if blue else GPIO.LOW)

    def supportedColors(self) -> list[LEDColor]:
        """
        Get a list of all supported colors that the RGB LED can display.
        :return: A list of all supported colors that the RGB LED can display.
        """
        return list(LEDColor)