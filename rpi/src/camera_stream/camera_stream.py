from flask import Flask, Response
from picamera2 import Picamera2
import io

CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480
CAMERA_RESOLUTION = (CAMERA_WIDTH, CAMERA_HEIGHT)
FORMAT = 'jpeg'
HOST = '0.0.0.0'
PORT = 8000

app = Flask(__name__)
camera = Picamera2()
camera.configure(camera.create_video_configuration(main={"size": CAMERA_RESOLUTION}))
camera.start()

def generate():
    while True:
        buf = io.BytesIO()
        camera.capture_file(buf, format=FORMAT)
        buf.seek(0)
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + buf.read() + b'\r\n')

@app.route('/stream')
def stream():
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

app.run(host=HOST, port=PORT)