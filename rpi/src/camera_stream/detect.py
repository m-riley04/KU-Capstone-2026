#!/usr/bin/env python3
"""
Person detection + dwell-time tracking pipeline for PolypodHW camera stream.

Flow: MediaMTX rpiCamera (cam) → cv2.VideoCapture RTSP → TFLite (MobileNet SSD COCO)
      → person filter + centroid tracker → OpenCV annotation
      → ffmpeg pipe → MediaMTX RTSP (cam_detect)

MediaMTX holds exclusive ownership of the camera hardware via its rpiCamera
source. detect.py reads already-decoded frames from the cam RTSP stream so
there is no hardware conflict.

Only "person" detections are kept. Each person is assigned a persistent ID
and the overlay shows how long they have been continuously in view.

The model is auto-downloaded on first run into ./models/.

Performance design
------------------
* Camera captures BGR888 directly — no full-resolution colour conversion.
* TFLite inference runs in a dedicated daemon thread so the encode loop
  (capture → annotate → pipe) never stalls waiting for inference.
* The inference queue has capacity 1; frames are dropped when the thread is
  busy, keeping the output stream at full FPS regardless of inference speed.
* Person class ID is resolved once at startup instead of per detection.
* Model input buffer is pre-allocated and reused every inference cycle.
* Pipe writes use memoryview to avoid a redundant bytes copy.

Contributors: Riley Meyerkorth, some GitHub Copilot suggestions/polish
"""

import os
import queue
import signal
import subprocess
import sys
import threading
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

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
WIDTH = 640
HEIGHT = 480
FPS = 30
CONFIDENCE_THRESHOLD = 0.5
RTSP_IN  = "rtsp://localhost:8554/cam"        # source: MediaMTX rpiCamera stream
RTSP_URL = "rtsp://localhost:8554/cam_detect"  # destination: annotated output

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


def _find_person_class_id(labels: list[str]) -> int:
    """Return the raw TFLite class ID that corresponds to 'person'.

    Many COCO TFLite labelmaps include a background placeholder ('???') at
    index 0, shifting all real class IDs by +1. This function handles both
    cases and returns the integer ID used by the model's output tensor.
    """
    _BG = {"???", "background", "__background__"}
    offset = 1 if (labels and labels[0].lower() in _BG) else 0
    for i, lbl in enumerate(labels):
        if lbl.lower() == "person":
            return i - offset
    return 0  # COCO person is always class 0 when no background row is present


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
# Inference worker (runs in a daemon thread)
# ---------------------------------------------------------------------------

# Shared detection results: list of (box, track_id, first_seen) tuples.
# The inference thread writes; the encode thread reads. Guarded by a Lock.
_results: list = []
_results_lock = threading.Lock()


def _inference_worker(
    stop_event: threading.Event,
    infer_q: queue.Queue,
    interpreter,
    input_details: list,
    output_details: list,
    model_h: int,
    model_w: int,
    person_class_id: int,
    tracker: "PersonTracker",
) -> None:
    input_idx   = input_details[0]["index"]
    boxes_idx   = output_details[0]["index"]
    classes_idx = output_details[1]["index"]
    scores_idx  = output_details[2]["index"]

    # Pre-allocate model input buffer — reused every inference cycle.
    input_buf = np.empty((1, model_h, model_w, 3), dtype=np.uint8)

    while not stop_event.is_set():
        try:
            small_bgr = infer_q.get(timeout=0.05)
        except queue.Empty:
            continue

        if small_bgr is None:
            break

        # Convert the small BGR frame to RGB in-place into the pre-allocated
        # buffer. At 300×300 this is ~270 KB — negligible cost.
        cv2.cvtColor(small_bgr, cv2.COLOR_BGR2RGB, dst=input_buf[0])

        interpreter.set_tensor(input_idx, input_buf)
        interpreter.invoke()

        boxes   = interpreter.get_tensor(boxes_idx)[0]    # [N, 4] ymin,xmin,ymax,xmax (normalised)
        classes = interpreter.get_tensor(classes_idx)[0]  # [N]
        scores  = interpreter.get_tensor(scores_idx)[0]   # [N]

        person_centroids: list[tuple[int, int]] = []
        person_boxes: list[tuple[int, int, int, int]] = []

        for i in range(len(scores)):
            if scores[i] < CONFIDENCE_THRESHOLD:
                continue
            if int(classes[i]) != person_class_id:
                continue

            ymin, xmin, ymax, xmax = boxes[i]
            x1 = max(0, int(xmin * WIDTH))
            y1 = max(0, int(ymin * HEIGHT))
            x2 = min(WIDTH,  int(xmax * WIDTH))
            y2 = min(HEIGHT, int(ymax * HEIGHT))

            person_boxes.append((x1, y1, x2, y2))
            person_centroids.append(((x1 + x2) // 2, (y1 + y2) // 2))

        tracks = tracker.update(person_centroids)
        centroid_to_id: dict[tuple[int, int], int] = {
            tuple(v["centroid"]): tid for tid, v in tracks.items()
        }

        new_results = []
        for box, centroid in zip(person_boxes, person_centroids):
            tid = centroid_to_id.get(centroid)
            if tid is None:
                continue
            # Store first_seen so the encode thread can compute a live duration.
            new_results.append((box, tid, tracks[tid]["first_seen"]))

        with _results_lock:
            _results[:] = new_results


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def run() -> None:
    _download_model()

    labels = _load_labels(LABELS_PATH)
    person_class_id = _find_person_class_id(labels)
    tracker = PersonTracker()

    interpreter = Interpreter(model_path=MODEL_PATH, num_threads=4)
    interpreter.allocate_tensors()
    input_details  = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    input_shape = input_details[0]["shape"]   # [1, H, W, 3]
    model_h, model_w = int(input_shape[1]), int(input_shape[2])

    # ------------------------------------------------------------------
    # RTSP input — read decoded frames from MediaMTX's rpiCamera stream.
    # This avoids competing with MediaMTX for exclusive camera hardware access.
    # CAP_PROP_BUFFERSIZE=1 keeps latency minimal (drop stale frames).
    # ------------------------------------------------------------------
    cap = cv2.VideoCapture(RTSP_IN, cv2.CAP_FFMPEG)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    if not cap.isOpened():
        print(f"Error: could not connect to {RTSP_IN}. Is MediaMTX running?", flush=True)
        sys.exit(1)

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
    # Inference thread — decouples TFLite from the encode loop.
    # Queue capacity 1: if inference is busy the latest frame is dropped
    # rather than blocking, keeping the output stream at full FPS.
    # ------------------------------------------------------------------
    infer_q: queue.Queue = queue.Queue(maxsize=1)
    stop_event = threading.Event()

    infer_thread = threading.Thread(
        target=_inference_worker,
        args=(
            stop_event, infer_q, interpreter,
            input_details, output_details,
            model_h, model_w, person_class_id, tracker,
        ),
        daemon=True,
        name="inference",
    )
    infer_thread.start()

    # ------------------------------------------------------------------
    # Graceful shutdown
    # ------------------------------------------------------------------
    def _shutdown(sig, frame):
        print("Shutting down detection stream...", flush=True)
        stop_event.set()
        try:
            infer_q.put_nowait(None)   # unblock thread if waiting on get()
        except queue.Full:
            pass
        cap.release()
        try:
            proc.stdin.close()
        except Exception:
            pass
        proc.wait()
        infer_thread.join(timeout=2)
        sys.exit(0)

    signal.signal(signal.SIGINT, _shutdown)
    signal.signal(signal.SIGTERM, _shutdown)

    print(f"Person detection + tracking active — publishing to {RTSP_URL}", flush=True)

    # ------------------------------------------------------------------
    # Encode loop — runs at full camera FPS regardless of inference speed.
    # ------------------------------------------------------------------
    while True:
        ret, frame_bgr = cap.read()
        if not ret:
            # RTSP hiccup — attempt to reconnect and keep going.
            print("RTSP read failed, reconnecting...", flush=True)
            cap.release()
            cap = cv2.VideoCapture(RTSP_IN, cv2.CAP_FFMPEG)
            cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            continue

        # Resize to model input size and queue for inference.
        # Dropping the frame (put_nowait) is intentional — the encoder
        # must never block waiting for inference to complete.
        small = cv2.resize(frame_bgr, (model_w, model_h))
        try:
            infer_q.put_nowait(small)
        except queue.Full:
            pass

        # Annotate with the latest available detections (may be a few frames
        # old if inference is slow — that's acceptable and far better than
        # stalling the stream).
        with _results_lock:
            current_results = list(_results)

        t_now = time.monotonic()
        for (x1, y1, x2, y2), tid, first_seen in current_results:
            _draw_person(frame_bgr, x1, y1, x2, y2, tid, t_now - first_seen)

        try:
            # memoryview avoids allocating a redundant bytes copy per frame.
            proc.stdin.write(memoryview(frame_bgr))
        except (BrokenPipeError, OSError):
            break

    stop_event.set()
    cap.release()


if __name__ == "__main__":
    run()
