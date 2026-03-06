"""
Name: detection.py
Description: Contains the dataclass for a detection.
Author: Riley Meyerkorth
Creation Date: 05 March 2026
"""

from dataclasses import dataclass

@dataclass
class Detection:
    """
    A dataclass representing a single detection from the YOLOv8 model.
    """
    class_id: int
    confidence: float
    box: object
    scale: float
