import 'package:flutter/services.dart';

/// this is the flutter side API for calling into the LED python code
/// python code handles the hardware, this is just able to call into it

///available colors currently, will need to be updated w python side as needed 
enum LEDColor { off, white, red, green, blue, yellow, cyan, magenta }

class LEDController {
  LEDController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('polypod/led');

  final MethodChannel _channel;

  Future<void> setColor(LEDColor color) async {
    try {
      await _channel.invokeMethod('setColor', {
        'color': color.name.toUpperCase(),
      });
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
