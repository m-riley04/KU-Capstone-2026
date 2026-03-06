"""
Name: constants.py
Description: Stores the constants used in the camera module.
Author: Riley Meyerkorth
Creation Date: 05 March 2026
Contributors: Riley Meyerkorth, Copilot Autocomplete
"""
import cv2, numpy as np
from ultralytics.utils import YAML
from ultralytics.utils.checks import check_yaml

### Paths
PYTORCH_MODEL_PATH = "yolov8n.pt"
DEFAULT_MODEL_PATH = "yolov8n.onnx"
DEFAULT_VIDEO_INDEX = 0
COCO_YAML_PATH = "coco8.yaml"

### Post-processing and ML
VIDEO_WIDTH = 640
VIDEO_HEIGHT = 640
SCORE_THRESHOLD = 0.5
SCALE_FACTOR = (1 / 255)
NMS_THRESHOLD = 0.45
NMS_ETA = 0.5

### UI Constants
LABEL_FONT = cv2.FONT_HERSHEY_SIMPLEX
LABEL_OFFSET_X = -10
LABEL_OFFSET_Y = -10
LABEL_FONT_SCALE = 0.5
LABEL_THICKNESS = 2
BOUNDING_BOX_THICKNESS = 2
KEY_QUIT = "q"
OPENCV_KEY_DELAY = 1
WINDOW_NAME = "Polypod Object Detection"

### Loaded values
CLASSES = YAML.load(check_yaml(COCO_YAML_PATH))["names"]
COLORS = np.random.uniform(0, 255, size=(len(CLASSES), 3))