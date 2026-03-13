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

def collect_bounding_boxes(outputs: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """
    Collect bounding boxes, confidence scores, and class IDs from the model output.
    Vectorized with NumPy for performance instead of a row-by-row Python loop.

    Returns:
        boxes (np.ndarray): Array of shape (N, 4) with [x, y, w, h] bounding boxes.
        scores (np.ndarray): Array of shape (N,) with confidence scores.
        class_ids (np.ndarray): Array of shape (N,) with class IDs.
    """
    data = outputs[0]  # shape: (num_detections, 4 + num_classes)
    classes_scores = data[:, 4:]

    # Get max score and corresponding class ID for each detection
    max_scores = np.max(classes_scores, axis=1)
    max_class_ids = np.argmax(classes_scores, axis=1)

    # Filter detections by score threshold
    mask = max_scores >= SCORE_THRESHOLD
    filtered = data[mask]
    scores = max_scores[mask]
    class_ids = max_class_ids[mask]

    # Convert from center format (cx, cy, w, h) to corner format (x, y, w, h)
    x_center, y_center = filtered[:, 0], filtered[:, 1]
    widths, heights = filtered[:, 2], filtered[:, 3]

    boxes = np.column_stack([
        x_center - widths / 2,
        y_center - heights / 2,
        widths,
        heights,
    ])

    return boxes, scores, class_ids