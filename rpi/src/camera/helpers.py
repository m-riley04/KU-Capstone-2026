"""
Name: gui_helpers.py
Description: Helper functions for the camera and ML GUI.
Author: Riley Meyerkorth
Creation Date: 05 March 2026
Contributors: Riley Meyerkorth, Copilot autocomplete, and heavily based on the work of Ultralytics (specifically, one of their examples)
https://github.com/ultralytics/ultralytics/tree/main/examples/YOLOv8-OpenCV-ONNX-Python
"""
import cv2, numpy as np
from constants import SCORE_THRESHOLD, BOUNDING_BOX_THICKNESS, LABEL_FONT, LABEL_FONT_SCALE, LABEL_OFFSET_X, LABEL_OFFSET_Y, LABEL_THICKNESS, CLASSES, COLORS
from detection import Detection

def draw_bounding_box(img: np.ndarray, detection: Detection) -> None:
    """
    Draw bounding boxes on the input image based on the provided arguments.

    Args:
        img (np.ndarray): The input image to draw the bounding box on.
        detection (Detection): The detection object containing the bounding box information.
    """
    class_id, confidence, box, scale = detection.class_id, detection.confidence, detection.box, detection.scale
    
    label = f"{CLASSES[class_id]} ({confidence:.2f})"
    color = COLORS[class_id]
    x = round(box[0] * scale)
    y = round(box[1] * scale)
    x_plus_w = round((box[0] + box[2]) * scale)
    y_plus_h = round((box[1] + box[3]) * scale)
    corner_nw = (x, y)
    corner_se = (x_plus_w, y_plus_h)
    cv2.rectangle(img, corner_nw, corner_se, color, BOUNDING_BOX_THICKNESS)
    cv2.putText(img, label, (x + LABEL_OFFSET_X, y + LABEL_OFFSET_Y), LABEL_FONT, LABEL_FONT_SCALE, color, LABEL_THICKNESS)

def collect_bounding_boxes(rows: int, outputs: np.ndarray) -> tuple[list, list, list]:
    """
    Collect bounding boxes, confidence scores, and class IDs from the model output.
    These are combined into a single function to because they are all performed in the same loop.
    """
    boxes = []
    scores = []
    class_ids = []
    for i in range(rows):
        classes_scores = outputs[0][i][4:]
        (_minScore, maxScore, _minClassLoc, (_x, maxClassIndex)) = cv2.minMaxLoc(classes_scores)
        if maxScore >= SCORE_THRESHOLD:
            # extract the bounding box information from the output
            x_center = outputs[0][i][0]
            y_center = outputs[0][i][1]
            width = outputs[0][i][2]
            height = outputs[0][i][3]

            # construct box in format [x, y, width, height] where x and y are the top-left corner of the box
            box = [
                x_center - (width/2), # left x
                y_center - (height/2), # top y
                width,
                height,
            ]

            # append the box, confidence score, and class ID to their respective lists
            boxes.append(box)
            scores.append(maxScore)
            class_ids.append(maxClassIndex)

    return boxes, scores, class_ids