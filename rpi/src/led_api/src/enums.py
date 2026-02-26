"""
Name: enums.py
Description: This file contains the enums used by the LED controller. These enums represent the different colors that the RGB LED can display.
Author: Riley Meyerkorth
Creation Date: 24 February 2026
"""

from enum import Enum

RGBColor = tuple[bool, bool, bool] # (red, green, blue)

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
