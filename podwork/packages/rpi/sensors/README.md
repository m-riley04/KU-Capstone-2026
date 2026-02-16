# BME680 Sensor Reader (Python)

This folder contains a minimal Python reader for the Adafruit BME680 sensor.

## Install

1) Enable I2C on the Raspberry Pi (raspi-config).
2) Install dependencies:

- `pip install -r requirements.txt`

## Run

- `python bme680_reader.py`

## Notes

- If your sensor uses SPI instead of I2C, the script needs to be adjusted.
- Update `sea_level_pressure` for accurate altitude/pressure calculations.
