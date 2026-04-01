# camera_stream

This folder contains 2 options for streaming the camera feed:

1. [MediaMTX](https://mediamtx.org/)
2. Python Flask Webpage

> NOTE: Currently, these are for locally accessable camera streams and are not being streamed to an external network.

## Setup

Run the following to install all global dependencies:

```bash
sudo apt update
sudp apt install -y libcap-dev python3-libcamera python3-kms++ rpicam-apps
```

To test whether the camera is detected and working, you can run the following:

```bash
rpicam-hello
```

To see a list of camera devices:

```bash
rpicam-hello --list-cameras
```

## Methods

### MediaMTX

A single binary that is configured using a YAML file ([`mediamtx.yml`](mediamtx.yml)).

The camera stream is pushed to multiple endpoints, but the best we've found is the WebRT stream located at the following URL:

```url
https://<rpi-ip>:8889/cam/
```

#### MeidaMTX Setup

You need to ensure that the binary is executable. From the repo's root directory, run the following commands to quickstart:

```bash
cd rpi/src/camera_stream
chmod +x mediamtx
./mediamtx
```

### Python Flask Webpage

Mainly used for testing. Probably to be deleted later.

Accessable at the following URL:

```url
https://<rpi-ip>:8000/stream/
```

#### Python Env Setup

The python implementation needs slightly more setup.

From the repo's root directory, run the following:

```bash
cd rpi/src/camera_stream
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```
