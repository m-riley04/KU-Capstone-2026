#!/usr/bin/env python3
"""
Person detection + dwell-time tracking pipeline for PolypodHW camera stream.

Flow: picamera2 → TFLite (MobileNet SSD COCO) → person filter + centroid
      tracker → OpenCV annotation → ffmpeg pipe → MediaMTX RTSP

Only "person" detections are kept. Each person is assigned a persistent ID
and the overlay shows how long they have been continuously in view.

The model is auto-downloaded on first run into ./models/.

Contributors: Riley Meyerkorth, some GitHub Copilot suggestions/polish
"""

import os
import sys
import signal
import subprocess
import time
import urllib.request
import zipfile

import cv2
import numpy as np

try:
    import tflite_runtime.interpreter as tflite
    Interpreter = tflite.Interpreter
except ImportError:
    # Newer Raspberry Pi OS (Bookworm) ships ai-edge-litert instead
    from ai_edge_litert.interpreter import Interpreter  # type: ignore

from picamera2 import Picamera2

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
WIDTH = 640
HEIGHT = 480
FPS = 30
CONFIDENCE_THRESHOLD = 0.5
RTSP_URL = "rtsp://localhost:8554/cam"

# Maximum pixel distance between a new detection centroid and an existing
# track centroid to be considered the same person.
MAX_CENTROID_DISTANCE = 80

# How many consecutive frames a track can go unmatched before it is dropped.
MAX_DISAPPEARED_FRAMES = 30

_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(_DIR, "models")
MODEL_PATH = os.path.join(MODEL_DIR, "detect.tflite")
LABELS_PATH = os.path.join(MODEL_DIR, "labelmap.txt")

_MODEL_ZIP_URL = (
    "https://storage.googleapis.com/download.tensorflow.org/models/"
    "tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip"
)

# ---------------------------------------------------------------------------
# Model helpers
# ---------------------------------------------------------------------------

def _download_model() -> None:
    """Download and unpack the MobileNet SSD TFLite model if not present."""
    if os.path.exists(MODEL_PATH) and os.path.exists(LABELS_PATH):
        return

    os.makedirs(MODEL_DIR, exist_ok=True)
    zip_path = os.path.join(MODEL_DIR, "model.zip")
    print("Downloading MobileNet SSD TFLite model...", flush=True)
    urllib.request.urlretrieve(_MODEL_ZIP_URL, zip_path)
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(MODEL_DIR)
    os.remove(zip_path)
    print("Model ready.", flush=True)


def _load_labels(path: str) -> list[str]:
    with open(path, "r") as f:
        lines = f.read().strip().splitlines()
    labels = []
    for line in lines:
        parts = line.strip().split(maxsplit=1)
        labels.append(parts[-1] if parts else "")
    return labels


def _resolve_label(labels: list[str], raw_class_id: int) -> str:
    """Map a raw TFLite class ID to its label name.

    Many COCO TFLite labelmaps include a background placeholder ("???") at
    index 0, so the real class 0 (person) lives at labelmap index 1.
    This function detects that case and applies the offset automatically.
    """
    _BACKGROUND_TOKENS = {"???", "background", "__background__"}
    offset = 1 if (labels and labels[0].lower() in _BACKGROUND_TOKENS) else 0
    idx = raw_class_id + offset
    return labels[idx] if idx < len(labels) else str(raw_class_id)


# ---------------------------------------------------------------------------
# Centroid-based person tracker
# ---------------------------------------------------------------------------

class PersonTracker:
    """Lightweight centroid tracker for person dwell-time measurement.

    Tracks are matched frame-to-frame by nearest centroid distance (no
    external dependencies beyond numpy). Each track stores:
      - centroid: (cx, cy) in pixels
      - first_seen: monotonic timestamp when the person first appeared
      - disappeared: consecutive frames since last matched
    """

    def __init__(
        self,
        max_disappeared: int = MAX_DISAPPEARED_FRAMES,
        max_distance: int = MAX_CENTROID_DISTANCE,
    ) -> None:
        self._next_id: int = 0
        self._tracks: dict[int, dict] = {}
        self.max_disappeared = max_disappeared
        self.max_distance = max_distance

    def update(self, centroids: list[tuple[int, int]]) -> dict[int, dict]:
        """Update tracks with a new list of detection centroids.

        Returns the current track dictionary keyed by track ID.
        """
        if not centroids:
            for tid in list(self._tracks):
                self._tracks[tid]["disappeared"] += 1
                if self._tracks[tid]["disappeared"] > self.max_disappeared:
                    del self._tracks[tid]
            return self._tracks

        if not self._tracks:
            for c in centroids:
                self._register(c)
            return self._tracks

        track_ids = list(self._tracks.keys())
        track_cents = np.array([self._tracks[tid]["centroid"] for tid in track_ids], dtype=float)
        new_cents = np.array(centroids, dtype=float)

        # Pairwise Euclidean distance matrix: (n_tracks × n_detections)
        D = np.linalg.norm(track_cents[:, None] - new_cents[None, :], axis=2)

        # Greedy assignment: process tracks in order of their closest detection
        rows = D.min(axis=1).argsort()
        cols = D.argmin(axis=1)[rows]

        used_rows: set[int] = set()
        used_cols: set[int] = set()

        for row, col in zip(rows, cols):
            if row in used_rows or col in used_cols:
                continue
            if D[row, col] > self.max_distance:
                continue
            tid = track_ids[row]
            self._tracks[tid]["centroid"] = centroids[col]
            self._tracks[tid]["disappeared"] = 0
            used_rows.add(row)
            used_cols.add(col)

        # Register new detections that had no matching track
        for col in range(len(centroids)):
            if col not in used_cols:
                self._register(centroids[col])

        # Age out unmatched tracks
        for row in range(len(track_ids)):
            if row not in used_rows:
                tid = track_ids[row]
                self._tracks[tid]["disappeared"] += 1
                if self._tracks[tid]["disappeared"] > self.max_disappeared:
                    del self._tracks[tid]

        return self._tracks

    def _register(self, centroid: tuple[int, int]) -> None:
        self._tracks[self._next_id] = {
            "centroid": centroid,
            "first_seen": time.monotonic(),
            "disappeared": 0,
        }
        self._next_id += 1


# ---------------------------------------------------------------------------
# Overlay helpers
# ---------------------------------------------------------------------------

def _format_duration(seconds: float) -> str:
    s = int(seconds)
    if s < 60:
        return f"{s}s"
    return f"{s // 60}m {s % 60}s"


def _draw_person(
    frame: np.ndarray,
    x1: int, y1: int, x2: int, y2: int,
    track_id: int,
    duration: float,
) -> None:
    label = f"Person #{track_id}  {_format_duration(duration)}"
    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)

    (text_w, text_h), baseline = cv2.getTextSize(
        label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1
    )
    bg_y1 = max(y1 - text_h - baseline - 4, 0)
    bg_y2 = max(y1, text_h + baseline + 4)
    cv2.rectangle(frame, (x1, bg_y1), (x1 + text_w + 4, bg_y2), (0, 255, 0), cv2.FILLED)
    cv2.putText(
        frame,
        label,
        (x1 + 2, max(y1 - 4, text_h)),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.5,
        (0, 0, 0),
        1,
        cv2.LINE_AA,
    )


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def run() -> None:
    _download_model()

    labels = _load_labels(LABELS_PATH)
    tracker = PersonTracker()

    interpreter = Interpreter(model_path=MODEL_PATH, num_threads=4)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Model input dimensions (usually 300×300 for MobileNet SSD)
    input_shape = input_details[0]["shape"]   # [1, H, W, 3]
    model_h, model_w = int(input_shape[1]), int(input_shape[2])

    # ------------------------------------------------------------------
    # Camera
    # ------------------------------------------------------------------
    picam2 = Picamera2()
    cam_config = picam2.create_video_configuration(
        main={"format": "RGB888", "size": (WIDTH, HEIGHT)},
        controls={"FrameRate": FPS},
    )
    picam2.configure(cam_config)
    picam2.start()

    # ------------------------------------------------------------------
    # ffmpeg pipe → MediaMTX RTSP
    # ------------------------------------------------------------------
    ffmpeg_cmd = [
        "ffmpeg", "-loglevel", "error",
        "-f", "rawvideo", "-pix_fmt", "bgr24",
        "-s", f"{WIDTH}x{HEIGHT}", "-r", str(FPS),
        "-i", "pipe:0",
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-tune", "zerolatency",
        "-pix_fmt", "yuv420p",
        "-g", str(FPS),
        "-f", "rtsp",
        RTSP_URL,
    ]
    proc = subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE)

    # ------------------------------------------------------------------
    # Graceful shutdown
    # ------------------------------------------------------------------
    def _shutdown(sig, frame):
        print("Shutting down detection stream...", flush=True)
        picam2.stop()
        try:
            proc.stdin.close()
        except Exception:
            pass
        proc.wait()
        sys.exit(0)

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)

    print(f"Person detection + tracking active — publishing to {RTSP_URL}", flush=True)

    # ------------------------------------------------------------------
    # Detection loop
    # ------------------------------------------------------------------
    now = time.monotonic

    while True:
        frame_rgb = picam2.capture_array()   # shape: (HEIGHT, WIDTH, 3), RGB

        resized = cv2.resize(frame_rgb, (model_w, model_h))
        input_data = np.expand_dims(resized, axis=0)   # [1, H, W, 3]

        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()

        # Output tensors (standard SSD order)
        boxes   = interpreter.get_tensor(output_details[0]["index"])[0]   # [N, 4] ymin,xmin,ymax,xmax (normalised)
        classes = interpreter.get_tensor(output_details[1]["index"])[0]   # [N]
        scores  = interpreter.get_tensor(output_details[2]["index"])[0]   # [N]

        # Convert to BGR for OpenCV / ffmpeg
        frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)

        # Collect person detections for this frame
        person_boxes: list[tuple[int, int, int, int]] = []
        person_centroids: list[tuple[int, int]] = []

        for i in range(len(scores)):
            if scores[i] < CONFIDENCE_THRESHOLD:
                continue
            if _resolve_label(labels, int(classes[i])).lower() != "person":
                continue

            ymin, xmin, ymax, xmax = boxes[i]
            x1 = int(xmin * WIDTH)
            y1 = int(ymin * HEIGHT)
            x2 = int(xmax * WIDTH)
            y2 = int(ymax * HEIGHT)

            person_boxes.append((x1, y1, x2, y2))
            person_centroids.append(((x1 + x2) // 2, (y1 + y2) // 2))

        # Update tracker and match track IDs back to bounding boxes
        tracks = tracker.update(person_centroids)

        # Build a centroid → track_id map for annotation
        centroid_to_id: dict[tuple[int, int], int] = {
            tuple(v["centroid"]): tid for tid, v in tracks.items()
        }

        t_now = now()
        for (x1, y1, x2, y2), centroid in zip(person_boxes, person_centroids):
            tid = centroid_to_id.get(centroid)
            if tid is None:
                continue
            duration = t_now - tracks[tid]["first_seen"]
            _draw_person(frame_bgr, x1, y1, x2, y2, tid, duration)

        try:
            proc.stdin.write(frame_bgr.tobytes())
        except BrokenPipeError:
            break

    picam2.stop()


if __name__ == "__main__":
    run()
