"""
Name: camera_test.py
Description: A simple script to test the camera and YOLOv8 model.
Author: Riley Meyerkorth
Creation Date: 05 March 2026
Contributors: Riley Meyerkorth, and heavily based on the work of Ultralytics (specifically, one of their examples)
https://github.com/ultralytics/ultralytics/tree/main/examples/YOLOv8-OpenCV-ONNX-Python
"""

import argparse, cv2, cv2.dnn
import numpy as np
from __future__ import annotations
from typing import Any
from constants import CLASSES, DEFAULT_MODEL_PATH, DEFAULT_VIDEO_INDEX, KEY_QUIT, NMS_ETA, NMS_THRESHOLD, OPENCV_KEY_DELAY, SCALE_FACTOR, SCORE_THRESHOLD, VIDEO_HEIGHT, VIDEO_WIDTH, WINDOW_NAME
from rpi.src.camera.helpers import collect_bounding_boxes, collect_bounding_boxes, draw_bounding_box
from rpi.src.camera.detection import Detection

def run(onnx_model: str, video_input: int) -> list[dict[str, Any]]:
    """Run the YOLOv8 model on the video input and return the detections.

    Args:
        onnx_model (str): Path to the ONNX model file.
        video_input (int): Video index for camera input.

    Returns:
        list[dict[str, Any]]: A list of dictionaries containing detection information.
    """
    # Load the ONNX model
    print("Reading ONNX model...")
    model: cv2.dnn.Net = cv2.dnn.readNetFromONNX(onnx_model)
    print("ONNX model loaded successfully.")

    # Start video capture
    print("Starting video capture...")
    cap = cv2.VideoCapture(video_input)
    if not cap.isOpened():
        print("Error: Could not open video.")
        return []
    print("Video capture started successfully.")

    # main capture loop
    while True:
        ret, frame = cap.read()
        if not ret:
            print("Failed to read frame")
            break

        # Read the input image
        [height, width, _] = frame.shape

        # Prepare a square image for inference
        length = max((height, width))
        image = np.zeros((length, length, 3), np.uint8)
        image[0:height, 0:width] = frame

        # Calculate scale factor
        scale = length / VIDEO_WIDTH

        # Preprocess the image and prepare blob for model
        blob = cv2.dnn.blobFromImage(image, scalefactor=SCALE_FACTOR, size=(VIDEO_WIDTH, VIDEO_HEIGHT), swapRB=True)
        model.setInput(blob)

        # Perform inference
        outputs = model.forward()

        # Prepare output array
        outputs = np.array([cv2.transpose(outputs[0])])
        rows = outputs.shape[1]

        # Iterate through output to collect bounding boxes, confidence scores, and class IDs
        boxes, scores, class_ids = collect_bounding_boxes(rows, outputs)

        # Apply NMS (Non-maximum suppression)
        result_boxes = np.array(cv2.dnn.NMSBoxes(boxes, scores, SCORE_THRESHOLD, NMS_THRESHOLD, NMS_ETA)).flatten()

        # Iterate through NMS results to draw bounding boxes and labels
        detections = []
        for index in result_boxes:
            index = int(index)
            box = boxes[index]
            detection = Detection(
                class_id=class_ids[index],
                confidence=scores[index],
                box=box,
                scale=scale,
            )
            detections.append(detection)
            draw_bounding_box(frame, detection)

        # Display the image with bounding boxes
        cv2.imshow(WINDOW_NAME, frame)

        # handle key press for quitting
        if cv2.waitKey(OPENCV_KEY_DELAY) & 0xFF == ord(KEY_QUIT):
            break

    # cleanup
    cap.release()
    cv2.destroyAllWindows()
    return detections

def main() -> None:
    """Main function to run the camera test."""
    # parse command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default=DEFAULT_MODEL_PATH, type=str, help="Input your ONNX model.")
    parser.add_argument("--video-index", dest="video_index", default=DEFAULT_VIDEO_INDEX, type=int, help="Video index for camera input.")
    args = parser.parse_args()

    # run main loop
    run(args.model, args.video_index)
    
if __name__ == "__main__":
    main()
