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
from constants import CLASS_ID_PERSON, DEFAULT_MODEL_PATH, DEFAULT_VIDEO_INDEX, KEY_QUIT, NMS_ETA, NMS_THRESHOLD, OPENCV_KEY_DELAY, SCALE_FACTOR, SCORE_THRESHOLD, VIDEO_HEIGHT, VIDEO_WIDTH, WINDOW_NAME
from helpers import collect_bounding_boxes, draw_bounding_box
from detection import Detection
from datetime import datetime, timedelta


# TODO: these globals should not exist. We should probs use a class to encapsulate state, but for now this works.
# See TODO in process_frame function for more details.
personDetectedIntialTimestamp = None
personDetected = False

def process_frame(cap: cv2.VideoCapture, model: cv2.dnn.Net) -> bool:
    """
    This function is ran every iteration of the main loop.
    It reads a frame from the video capture, processes it with the model, and displays the results.

    Returns False if the user has requested to quit or an error occurs, and True otherwise.
    """

    ret, frame = cap.read()
    if not ret:
        print("Failed to read frame")
        return False

    # Read the input image
    [height, width, _] = frame.shape
    length = max((height, width))
    scale = length / VIDEO_WIDTH

    # Resize frame first, then pad into a small 640x640 buffer
    # (avoids allocating a large intermediate square image, e.g. 1920x1920)
    resized_h = int(height / scale)
    resized_w = int(width / scale)
    image = np.zeros((VIDEO_HEIGHT, VIDEO_WIDTH, 3), np.uint8)
    image[0:resized_h, 0:resized_w] = cv2.resize(frame, (resized_w, resized_h))

    # Preprocess the image and prepare blob for model
    blob = cv2.dnn.blobFromImage(image, scalefactor=SCALE_FACTOR, size=(VIDEO_WIDTH, VIDEO_HEIGHT), swapRB=True)
    model.setInput(blob)

    # Perform inference
    outputs = model.forward()

    # Prepare output array
    outputs = np.array([cv2.transpose(outputs[0])])

    # Collect bounding boxes, confidence scores, and class IDs (vectorized)
    boxes, scores, class_ids = collect_bounding_boxes(outputs)

    # Filter for person class before NMS to reduce processing
    if len(boxes) > 0:
        person_mask = class_ids == CLASS_ID_PERSON
        boxes = boxes[person_mask]
        scores = scores[person_mask]
        class_ids = class_ids[person_mask]

    # Apply NMS (Non-maximum suppression)
    detections = []
    if len(boxes) > 0:
        result_indices = np.array(
            cv2.dnn.NMSBoxes(boxes.tolist(), scores.tolist(), SCORE_THRESHOLD, NMS_THRESHOLD, NMS_ETA)
        ).flatten()

        for index in result_indices:
            index = int(index)
            detection = Detection(
                class_id=class_ids[index],
                confidence=scores[index],
                box=boxes[index],
                scale=scale,
            )
            detections.append(detection)
            draw_bounding_box(frame, detection)

    # TODO: very hacky. Remove global vars and use class to encapsulate state instead. This is just for testing purposes.
    if len(detections) > 0:
        global personDetectedIntialTimestamp, personDetected
        if not personDetected:
            personDetectedIntialTimestamp = datetime.now()
            personDetected = True
    else:
        personDetectedIntialTimestamp = None
        personDetected = False

    # Add current time since initial detection and person detection status to the frame
    if personDetectedIntialTimestamp is not None:
        timeSinceInitialDetection = datetime.now() - personDetectedIntialTimestamp
        cv2.putText(frame, f"Person Detected for {timeSinceInitialDetection.total_seconds():.2f} seconds", (10, frame.shape[0] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)

    if personDetected:
        cv2.putText(frame, "Person Detected", (10, frame.shape[0] - 30), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
    else:
        cv2.putText(frame, "No Person Detected", (10, frame.shape[0] - 30), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)

    # Display the image with bounding boxes
    cv2.imshow(WINDOW_NAME, frame)

    # handle key press for quitting
    if cv2.waitKey(OPENCV_KEY_DELAY) & 0xFF == ord(KEY_QUIT):
        return False

    return True

def run(onnx_model: str, video_input: int) -> None:
    """Run the YOLOv8 model on the video input and return the detections.

    Args:
        onnx_model (str): Path to the ONNX model file.
        video_input (int): Video index for camera input.
    """
    # Load the ONNX model
    print("Reading ONNX model...")
    model: cv2.dnn.Net = cv2.dnn.readNetFromONNX(onnx_model)
    model.setPreferableBackend(cv2.dnn.DNN_BACKEND_OPENCV)
    model.setPreferableTarget(cv2.dnn.DNN_TARGET_CPU)
    print("ONNX model loaded successfully.")

    # Start video capture
    print("Starting video capture...")
    
    cap = cv2.VideoCapture(video_input)
    if not cap.isOpened():
        print("Error: Could not open video.")
        return []
    print("Video capture started successfully.")

    # main capture loop
    while process_frame(cap, model): pass

    # cleanup
    cap.release()
    cv2.destroyAllWindows()

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
