"""
Name: convert.py
Description: A simple script to convert a YOLOv8 model to ONNX format. Necessary for running the model on the Raspberry Pi with OpenCV's DNN module.
Author: Riley Meyerkorth
Creation Date: 05 March 2026
"""

from ultralytics import YOLO
from constants import PYTORCH_MODEL_PATH, VIDEO_WIDTH

# load and re-export model in ONNX format
model = YOLO(PYTORCH_MODEL_PATH)
model.export(format="onnx", imgsz=VIDEO_WIDTH, simplify=True)