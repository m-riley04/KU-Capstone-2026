'''
Author: Aiden Burke
Last Updated: 02/24/2026
Read data from the BME680 sensor
'''

import time

import board
import busio
import adafruit_bme680


def main():
    i2c = busio.I2C(board.SCL, board.SDA)
    sensor = adafruit_bme680.Adafruit_BME680_I2C(i2c)

    while True:
        temperature_c = sensor.temperature
        temperature_f = temperature_c * 9 / 5 + 32
        humidity = sensor.humidity
        pressure_hpa = sensor.pressure
        gas_ohms = sensor.gas
        # TODO: convert gas resistance to air quality index using Bosch library

        print(
            f"Temp: {temperature_c:.2f} C ({temperature_f:.2f} F) | "
            f"Humidity: {humidity:.2f}% | "
            f"Pressure: {pressure_hpa:.2f} hPa | "
            f"Gas: {gas_ohms:.0f} ohms"
        )

        if temperature_c > 26: pass # TODO: trigger high temperature alert
        if temperature_c < 18: pass # TODO: trigger low temperature alert

        # TODO: build in alerts for poor air quality, high/low temperature, etc
        # and pass that information to the main podwork system via notifications

        time.sleep(3)


if __name__ == "__main__":
    main()
