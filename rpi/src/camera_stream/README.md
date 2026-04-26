# camera_stream

This folder contains a [MediaMTX](https://mediamtx.org/) instance for streaming the camera feed. I would've liked to have MediaMTX downloaded during setup and not stored in the repo, but we found this was the simplest way to do it.

> NOTE: Currently, these are for locally accessable camera streams and are not being streamed to an external network.

## Setup

If you haven't un the following to install all global dependencies:

```bash
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y libcap-dev python3-libcamera python3-kms++ libcamera-apps rpicam-apps
```

To test whether the camera is detected and working, you can run the following:

```bash
rpicam-hello
```

To see a list of camera devices:

```bash
rpicam-hello --list-cameras
```

## MediaMTX

A single binary that is configured using a YAML file ([`mediamtx.yml`](mediamtx.yml)).

The camera stream is pushed to multiple endpoints, but the best we've found is the WebRT stream located at the following URL (configurable in the YAML file):

```url
https://<rpi-ip>:8889/cam/
```

### MeidaMTX Setup

You need to ensure that the binary is executable. From the repo's root directory, run the following commands to quickstart:

```bash
cd rpi/src/camera_stream
chmod +x mediamtx
./mediamtx
```
