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
        # TODO: convert gas resistance to air quality index

        print(
            f"Temp: {temperature_c:.2f} C ({temperature_f:.2f} F) | "
            f"Humidity: {humidity:.2f}% | "
            f"Pressure: {pressure_hpa:.2f} hPa | "
            f"Gas: {gas_ohms:.0f} ohms"
        )

        time.sleep(3)


if __name__ == "__main__":
    main()
